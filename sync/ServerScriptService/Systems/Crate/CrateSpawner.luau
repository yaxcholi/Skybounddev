--[[
	Studio setup:
	1. Create ServerStorage.Assets.Crates with models named Common, Uncommon, Rare, Legendary (Crate-tagged, Door, Main, Interaction, LootGen).
	2. Place invisible BasePart markers tagged CrateSpawner on island prefabs under ServerStorage.ProcGen.
	3. Remove pre-baked crates at those positions to avoid duplicates.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Component = require(ReplicatedStorage.Packages.Component)
local ProcGenConfig = require(ReplicatedStorage.Data.ProcGenConfig)
local ProcGenRandom = require(ReplicatedStorage.Utils.ProcGenRandom)
local CrateSpawnUtil = require(ServerScriptService.Systems.Crate.CrateSpawnUtil)

local CrateSpawner = Component.new({ Tag = "CrateSpawner" })

function CrateSpawner:Construct()
	self._cratesFolder = ServerStorage:FindFirstChild("Assets")
		and ServerStorage.Assets:FindFirstChild("Crates")
end

function CrateSpawner:Start()
	self.Instance.Transparency = 1
	self.Instance.CanCollide = false
	self.Instance.Material = Enum.Material.SmoothPlastic

	self:TrySpawn()
end

function CrateSpawner:TrySpawn()
	if not self._cratesFolder then
		warn("CrateSpawner: ServerStorage.Assets.Crates folder not found")
		return
	end

	local island = CrateSpawnUtil.getIslandAncestor(self.Instance)
	local shouldSpawn: boolean

	if island then
		local tier = island:GetAttribute("IslandTier") or "Small"
		local spawnChance = ProcGenConfig.CRATE_SPAWN_CHANCE_BY_TIER[tier]
			or ProcGenConfig.CRATE_SPAWN_CHANCE_BY_TIER.Small
		shouldSpawn = ProcGenRandom.get():NextNumber() < spawnChance
	else
		shouldSpawn = true
	end

	if not shouldSpawn then
		return
	end

	local tier = CrateSpawnUtil.getIslandTier(self.Instance)
	local template = CrateSpawnUtil.getCrateTemplate(self._cratesFolder, tier)
	if not template then
		return
	end

	local spawnCF: CFrame
	local container = island and island:FindFirstChild("CrateContainer", true)
	if container then
		local sx = container.Size.X / 2 * 0.8
		local sz = container.Size.Z / 2 * 0.8
		local rx = ProcGenRandom.get():NextNumber(-sx, sx)
		local rz = ProcGenRandom.get():NextNumber(-sz, sz)
		spawnCF = container.CFrame * CFrame.new(rx, container.Size.Y / 2 + 1.5, rz)
			* CFrame.Angles(0, ProcGenRandom.get():NextNumber(0, math.pi * 2), 0)
	else
		spawnCF = self.Instance:GetPivot() * CFrame.Angles(0, ProcGenRandom.get():NextNumber(0, math.pi * 2), 0)
	end

	local crate = template:Clone()
	crate:PivotTo(spawnCF)
	crate.Parent = island or self.Instance.Parent
end

function CrateSpawner:Stop() end

return CrateSpawner
