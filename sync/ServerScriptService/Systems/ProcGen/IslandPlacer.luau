local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProcGenConfig = require(ReplicatedStorage.Data.ProcGenConfig)

export type PlacementState = {
	consecutiveLefts: number,
	consecutiveRights: number,
}

export type Obstacle = {
	cf: CFrame,
	size: Vector3,
	instance: Model,
}

local IslandPlacer = {}

local TIER_ORDER = { "Small", "Medium", "Large" }

function IslandPlacer.createPlacementState(): PlacementState
	return {
		consecutiveLefts = 0,
		consecutiveRights = 0,
	}
end

function IslandPlacer.rollTier(random: Random, weights: { [string]: number }): string
	local roll = random:NextNumber()
	local cumulative = 0

	for _, tier in TIER_ORDER do
		cumulative += weights[tier] or 0
		if roll <= cumulative then
			return tier
		end
	end

	return "Small"
end

function IslandPlacer.pickSide(state: PlacementState, random: Random): (boolean, PlacementState)
	local isLeft: boolean

	if state.consecutiveLefts >= 2 then
		isLeft = false
	elseif state.consecutiveRights >= 2 then
		isLeft = true
	else
		isLeft = random:NextNumber() < 0.5
	end

	if isLeft then
		return true, {
			consecutiveLefts = state.consecutiveLefts + 1,
			consecutiveRights = 0,
		}
	end

	return false, {
		consecutiveLefts = 0,
		consecutiveRights = state.consecutiveRights + 1,
	}
end

function IslandPlacer.getTemplate(templates: Instance, tier: string, random: Random): Model?
	local folder = templates:FindFirstChild(`{tier}Islands`)
	if not folder then
		return nil
	end

	local children = folder:GetChildren()
	if #children == 0 then
		return nil
	end

	return children[random:NextInteger(1, #children)]:Clone()
end

function IslandPlacer.registerObstacle(model: Model, obstacles: { Obstacle })
	local cf, size = model:GetBoundingBox()
	table.insert(obstacles, {
		cf = cf,
		size = size,
		instance = model,
	})
end

function IslandPlacer.unregisterObstacle(model: Model, obstacles: { Obstacle })
	for index = #obstacles, 1, -1 do
		if obstacles[index].instance == model then
			table.remove(obstacles, index)
		end
	end
end

function IslandPlacer.place(
	random: Random,
	templates: Instance,
	z: number,
	phaseIndex: number,
	state: PlacementState,
	parent: Instance,
	obstacles: { Obstacle },
	spawnOrder: number
): (Model?, PlacementState)
	local weights = ProcGenConfig.PHASE_SIZE_WEIGHTS[phaseIndex] or ProcGenConfig.SIZE_WEIGHTS
	local tier = IslandPlacer.rollTier(random, weights)
	local template = IslandPlacer.getTemplate(templates, tier, random)

	if not template then
		return nil, state
	end

	local isLeft, newState = IslandPlacer.pickSide(state, random)
	local tierXRange = ProcGenConfig.ISLAND_X_RANGE_BY_TIER[tier] or ProcGenConfig.ISLAND_X_RANGE_BY_TIER.Small
	local xRange = isLeft and tierXRange.Left or tierXRange.Right
	local xOffset = random:NextNumber(xRange[1], xRange[2])
	local yOffset = random:NextNumber(ProcGenConfig.ISLAND_Y_RANGE[1], ProcGenConfig.ISLAND_Y_RANGE[2])

	template:PivotTo(
		CFrame.new(xOffset, yOffset, z) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
	)

	local templateName = template.Name
	template.Name = `Island_{spawnOrder}_{templateName}`
	template:SetAttribute("IslandTier", tier)
	template:SetAttribute("SpawnOrder", spawnOrder)
	template:SetAttribute("TemplateName", templateName)
	template:SetAttribute("SpawnZ", z)
	template.Parent = parent

	IslandPlacer.registerObstacle(template, obstacles)

	return template, newState
end

return IslandPlacer
