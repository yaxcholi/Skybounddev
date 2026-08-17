--[[
	Studio setup:
	1. Create ServerStorage.Assets.Enemies with enemy Model templates (EnemyAI + MeleeEnemy/RangedEnemy tags, PrimaryPart set).
	2. Name templates to match ProcGenConfig.NPC_WEIGHTS_BY_TIER keys (e.g. MeleeGrunt, RangedGrunt).
	3. Place invisible BasePart markers tagged NPCSpawner on island prefabs under ServerStorage.ProcGen.
	4. Remove pre-baked enemies at those positions to avoid duplicates.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local ProcGenConfig = require(ReplicatedStorage.Data.ProcGenConfig)
local ProcGenRandom = require(ReplicatedStorage.Utils.ProcGenRandom)

local NPCSpawner = Component.new({ Tag = "NPCSpawner", Extensions = { TroveAdder } })

local function getIslandTier(instance: Instance): string
	local current: Instance? = instance
	while current do
		local tier = current:GetAttribute("IslandTier")
		if tier then
			return tier
		end
		current = current.Parent
	end

	return "Small"
end

local function getIslandAncestor(instance: Instance): Model?
	local current: Instance? = instance
	while current do
		if current:GetAttribute("IslandTier") then
			return current :: Model
		end
		current = current.Parent
	end

	return nil
end

local function rollWeighted(weights: { [string]: number }): string
	local roll = ProcGenRandom.get():NextNumber()
	local cumulative = 0

	for name, weight in weights do
		cumulative += weight
		if roll <= cumulative then
			return name
		end
	end

	for name in weights do
		return name
	end

	return ""
end

function NPCSpawner:Construct()
	self._enemiesFolder = ServerStorage:FindFirstChild("Assets")
		and ServerStorage.Assets:FindFirstChild("Enemies")
end

function NPCSpawner:Start()
	self.Instance.Transparency = 1
	self.Instance.CanCollide = false
	self.Instance.Material = Enum.Material.SmoothPlastic

	self:Spawn()
end

function NPCSpawner:Spawn()
	if not self._enemiesFolder then
		warn("NPCSpawner: ServerStorage.Assets.Enemies folder not found")
		return
	end

	local tier = getIslandTier(self.Instance)
	local weights = ProcGenConfig.NPC_WEIGHTS_BY_TIER[tier] or ProcGenConfig.NPC_WEIGHTS_BY_TIER.Small
	local templateName = rollWeighted(weights)

	if templateName == "" then
		warn("NPCSpawner: no weights configured for tier", tier)
		return
	end

	local template = self._enemiesFolder:FindFirstChild(templateName)
	if not template then
		warn(`NPCSpawner: missing enemy template "{templateName}"`)
		return
	end

	local island = getIslandAncestor(self.Instance)
	local npc = template:Clone()
	npc:PivotTo(self.Instance:GetPivot() * CFrame.Angles(0, ProcGenRandom.get():NextNumber(0, math.pi * 2), 0))
	npc.Parent = island or self.Instance.Parent
end

function NPCSpawner:Stop() end

return NPCSpawner
