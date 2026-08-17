--[[
	Studio setup:
	1. Create ServerStorage.Assets.Enemies with enemy Model templates (EnemyAI + MeleeEnemy/RangedEnemy tags, PrimaryPart set).
	2. Name templates to match ProcGenConfig.NPC_WEIGHTS_BY_TIER keys (e.g. MeleeGrunt, RangedGrunt).
	3. Place a BasePart tagged NPCSpawnerZone sized to the area you want filled.
	4. Optional attribute: MaxNPCs (caps how many slots rarity is applied to).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local ProcGenConfig = require(ReplicatedStorage.Data.ProcGenConfig)
local ProcGenRandom = require(ReplicatedStorage.Utils.ProcGenRandom)

local NPC_MARGIN = 2
local RAYCAST_DEPTH = 100
local MAX_ATTEMPTS_MULTIPLIER = 8

local NPCSpawnerZone = Component.new({ Tag = "NPCSpawnerZone" })

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

local function getIslandTier(instance: Instance): string
	local island = getIslandAncestor(instance)
	if island then
		return island:GetAttribute("IslandTier") or "Small"
	end

	return "Small"
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

local function getHalfExtentAlongAxis(part: BasePart, axis: Vector3): number
	local up = axis.Unit
	return math.abs(part.CFrame.UpVector:Dot(up)) * part.Size.Y / 2
		+ math.abs(part.CFrame.RightVector:Dot(up)) * part.Size.X / 2
		+ math.abs(part.CFrame.LookVector:Dot(up)) * part.Size.Z / 2
end

local function alignNpcToSurface(npc: Model, root: BasePart, hitPosition: Vector3, normal: Vector3, yRotation: number)
	local up = normal.Unit
	local referenceForward = Vector3.new(math.cos(yRotation), 0, math.sin(yRotation))
	local projectedForward = referenceForward - referenceForward:Dot(up) * up

	if projectedForward.Magnitude < 0.01 then
		projectedForward = Vector3.new(1, 0, 0) - Vector3.new(1, 0, 0):Dot(up) * up
	end
	projectedForward = projectedForward.Unit

	local rootCenter = hitPosition + up * (getHalfExtentAlongAxis(root, up) + 0.01)
	local targetRootCFrame = CFrame.lookAt(rootCenter, rootCenter + projectedForward, up)
	local pivotToRoot = npc:GetPivot():ToObjectSpace(root.CFrame)

	npc:PivotTo(targetRootCFrame * pivotToRoot:Inverse())
end

local function getFootprintSize(model: Model): (number, number)
	local _, size = model:GetBoundingBox()
	return size.X / 2 + NPC_MARGIN / 2, size.Z / 2 + NPC_MARGIN / 2
end

local function overlapsXZ(
	center: Vector3,
	halfX: number,
	halfZ: number,
	placed: { { center: Vector3, halfX: number, halfZ: number } }
): boolean
	for _, footprint in placed do
		if math.abs(center.X - footprint.center.X) < halfX + footprint.halfX
			and math.abs(center.Z - footprint.center.Z) < halfZ + footprint.halfZ
		then
			return true
		end
	end

	return false
end

function NPCSpawnerZone:Construct()
	self._enemiesFolder = ServerStorage:FindFirstChild("Assets")
		and ServerStorage.Assets:FindFirstChild("Enemies")
end

function NPCSpawnerZone:Start()
	self.Instance.Transparency = 1
	self.Instance.CanCollide = false
	self.Instance.Material = Enum.Material.SmoothPlastic

	self:FillZone()
end

function NPCSpawnerZone:FillZone()
	if not self._enemiesFolder then
		warn("NPCSpawnerZone: ServerStorage.Assets.Enemies folder not found")
		return
	end

	local island = getIslandAncestor(self.Instance)
	local tier = getIslandTier(self.Instance)
	local weights = ProcGenConfig.NPC_WEIGHTS_BY_TIER[tier] or ProcGenConfig.NPC_WEIGHTS_BY_TIER.Small

	local zoneCFrame = self.Instance.CFrame
	local zoneSize = self.Instance.Size
	local halfX = zoneSize.X / 2
	local halfZ = zoneSize.Z / 2

	local templateFootprints = {}
	local avgFootprintX, avgFootprintZ = 0, 0
	local templateCount = 0

	for templateName in weights do
		local template = self._enemiesFolder:FindFirstChild(templateName)
		if not template then
			continue
		end

		local footprintX, footprintZ = getFootprintSize(template)
		templateFootprints[templateName] = { footprintX, footprintZ }
		avgFootprintX += footprintX * 2
		avgFootprintZ += footprintZ * 2
		templateCount += 1
	end

	if templateCount == 0 then
		warn("NPCSpawnerZone: no configured enemy templates found in ServerStorage.Assets.Enemies")
		return
	end

	avgFootprintX /= templateCount
	avgFootprintZ /= templateCount

	local computedMax = math.max(
		1,
		math.floor(zoneSize.X / avgFootprintX) * math.floor(zoneSize.Z / avgFootprintZ)
	)
	local maxSlots = self.Instance:GetAttribute("MaxNPCs") or computedMax
	maxSlots = math.min(maxSlots, computedMax)

	local targetCount = 0
	if not island then
		targetCount = maxSlots
	else
		local spawnChance = ProcGenConfig.CRATE_SPAWN_CHANCE_BY_TIER[tier]
			or ProcGenConfig.CRATE_SPAWN_CHANCE_BY_TIER.Small

		for _ = 1, maxSlots do
			if ProcGenRandom.get():NextNumber() < spawnChance then
				targetCount += 1
			end
		end
	end

	if targetCount == 0 then
		return
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { self.Instance }

	local placedFootprints: { { center: Vector3, halfX: number, halfZ: number } } = {}
	local placedCount = 0
	local attempts = 0
	local maxAttempts = targetCount * MAX_ATTEMPTS_MULTIPLIER

	while placedCount < targetCount and attempts < maxAttempts do
		attempts += 1

		local templateName = rollWeighted(weights)
		if templateName == "" then
			continue
		end

		local template = self._enemiesFolder:FindFirstChild(templateName)
		if not template then
			warn(`NPCSpawnerZone: missing enemy template "{templateName}"`)
			continue
		end

		local footprint = templateFootprints[templateName]
		local footprintX, footprintZ
		if footprint then
			footprintX, footprintZ = footprint[1], footprint[2]
		else
			footprintX, footprintZ = getFootprintSize(template)
			templateFootprints[templateName] = { footprintX, footprintZ }
		end

		local localX = ProcGenRandom.get():NextNumber(-halfX, halfX)
		local localZ = ProcGenRandom.get():NextNumber(-halfZ, halfZ)
		local rayOrigin = (zoneCFrame * CFrame.new(localX, zoneSize.Y / 2 + 5, localZ)).Position
		local result = workspace:Raycast(rayOrigin, Vector3.new(0, -RAYCAST_DEPTH, 0), raycastParams)

		if not result or not result.Instance:IsA("BasePart") then
			continue
		end

		if overlapsXZ(result.Position, footprintX, footprintZ, placedFootprints) then
			continue
		end

		local root = template.PrimaryPart
		if not root then
			warn(`NPCSpawnerZone: enemy template "{templateName}" is missing PrimaryPart`)
			continue
		end

		local npc = template:Clone()
		local yRotation = ProcGenRandom.get():NextNumber(0, math.pi * 2)
		alignNpcToSurface(npc, root, result.Position, result.Normal, yRotation)
		npc.Parent = island or self.Instance.Parent

		table.insert(placedFootprints, {
			center = result.Position,
			halfX = footprintX,
			halfZ = footprintZ,
		})
		table.insert(raycastParams.FilterDescendantsInstances, npc)
		placedCount += 1
	end
end

function NPCSpawnerZone:Stop() end

return NPCSpawnerZone
