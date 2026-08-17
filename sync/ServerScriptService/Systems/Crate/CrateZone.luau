--[[
	Studio setup:
	1. Create ServerStorage.Assets.Crates with models named Common, Uncommon, Rare, Legendary.
	2. Place a BasePart tagged CrateZone sized to the area you want filled.
	3. Optional attribute: MaxCrates (caps how many slots rarity is applied to).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Component = require(ReplicatedStorage.Packages.Component)
local ProcGenConfig = require(ReplicatedStorage.Data.ProcGenConfig)
local ProcGenRandom = require(ReplicatedStorage.Utils.ProcGenRandom)
local CrateSpawnUtil = require(ServerScriptService.Systems.Crate.CrateSpawnUtil)

local CRATE_MARGIN = 2
local RAYCAST_DEPTH = 100
local MAX_ATTEMPTS_MULTIPLIER = 8

local CrateZone = Component.new({ Tag = "CrateZone" })

local function getIslandAncestor(instance: Instance): Model?
	return CrateSpawnUtil.getIslandAncestor(instance)
end

local function getHalfExtentAlongAxis(part: BasePart, axis: Vector3): number
	local up = axis.Unit
	return math.abs(part.CFrame.UpVector:Dot(up)) * part.Size.Y / 2
		+ math.abs(part.CFrame.RightVector:Dot(up)) * part.Size.X / 2
		+ math.abs(part.CFrame.LookVector:Dot(up)) * part.Size.Z / 2
end

local function alignCrateToSurface(crate: Model, main: BasePart, hitPosition: Vector3, normal: Vector3, yRotation: number)
	local up = normal.Unit
	local referenceForward = Vector3.new(math.cos(yRotation), 0, math.sin(yRotation))
	local projectedForward = referenceForward - referenceForward:Dot(up) * up

	if projectedForward.Magnitude < 0.01 then
		projectedForward = Vector3.new(1, 0, 0) - Vector3.new(1, 0, 0):Dot(up) * up
	end
	projectedForward = projectedForward.Unit

	local mainCenter = hitPosition + up * (getHalfExtentAlongAxis(main, up) + 0.01)
	local targetMainCFrame = CFrame.lookAt(mainCenter, mainCenter + projectedForward, up)
	local pivotToMain = crate:GetPivot():ToObjectSpace(main.CFrame)

	crate:PivotTo(targetMainCFrame * pivotToMain:Inverse())
end

local function getFootprintSize(model: Model): (number, number)
	local _, size = model:GetBoundingBox()
	return size.X / 2 + CRATE_MARGIN / 2, size.Z / 2 + CRATE_MARGIN / 2
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

function CrateZone:Construct()
	self._cratesFolder = ServerStorage:FindFirstChild("Assets")
		and ServerStorage.Assets:FindFirstChild("Crates")
end

function CrateZone:Start()
	self.Instance.Transparency = 1
	self.Instance.CanCollide = false
	self.Instance.Material = Enum.Material.SmoothPlastic

	self:FillZone()
end

function CrateZone:FillZone()
	if not self._cratesFolder then
		warn("CrateZone: ServerStorage.Assets.Crates folder not found")
		return
	end

	local templates = {}
	for _, rarity in ProcGenConfig.CRATE_RARITIES do
		local template = self._cratesFolder:FindFirstChild(rarity)
		if template then
			table.insert(templates, template)
		end
	end

	if #templates == 0 then
		warn("CrateZone: ServerStorage.Assets.Crates folder has no rarity templates (Common, Uncommon, Rare, Legendary)")
		return
	end

	local island = getIslandAncestor(self.Instance)
	local tier = CrateSpawnUtil.getIslandTier(self.Instance)
	local zoneCFrame = self.Instance.CFrame
	local zoneSize = self.Instance.Size
	local halfX = zoneSize.X / 2
	local halfZ = zoneSize.Z / 2

	local avgFootprintX, avgFootprintZ = 0, 0
	for _, template in templates do
		local footprintX, footprintZ = getFootprintSize(template)
		avgFootprintX += footprintX * 2
		avgFootprintZ += footprintZ * 2
	end
	avgFootprintX /= #templates
	avgFootprintZ /= #templates

	local computedMax = math.max(
		1,
		math.floor(zoneSize.X / avgFootprintX) * math.floor(zoneSize.Z / avgFootprintZ)
	)
	local maxSlots = self.Instance:GetAttribute("MaxCrates") or computedMax
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

		local localX = ProcGenRandom.get():NextNumber(-halfX, halfX)
		local localZ = ProcGenRandom.get():NextNumber(-halfZ, halfZ)
		local rayOrigin = (zoneCFrame * CFrame.new(localX, zoneSize.Y / 2 + 5, localZ)).Position
		local result = workspace:Raycast(rayOrigin, Vector3.new(0, -RAYCAST_DEPTH, 0), raycastParams)

		if not result or not result.Instance:IsA("BasePart") then
			continue
		end

		local template = CrateSpawnUtil.getCrateTemplate(self._cratesFolder, tier)
		if not template then
			continue
		end

		local footprintX, footprintZ = getFootprintSize(template)

		if overlapsXZ(result.Position, footprintX, footprintZ, placedFootprints) then
			continue
		end

		local main = template:FindFirstChild("Main") :: BasePart?
		if not main then
			warn(`CrateZone: crate template "{template.Name}" is missing Main part`)
			continue
		end

		local crate = template:Clone()
		local yRotation = ProcGenRandom.get():NextNumber(0, math.pi * 2)
		alignCrateToSurface(crate, main, result.Position, result.Normal, yRotation)
		crate.Parent = island or self.Instance.Parent

		table.insert(placedFootprints, {
			center = result.Position,
			halfX = footprintX,
			halfZ = footprintZ,
		})
		table.insert(raycastParams.FilterDescendantsInstances, crate)
		placedCount += 1
	end
end

function CrateZone:Stop() end

return CrateZone
