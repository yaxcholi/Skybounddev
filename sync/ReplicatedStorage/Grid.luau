local GRID_SIZE = 7.5

local Grid = {}
Grid.GRID_SIZE = GRID_SIZE

local function positionToString(gridPosition: Vector2)
	return string.format("%d,%d", gridPosition.X, gridPosition.Y)
end

function Grid.getCellCFrames(buildAreaModel: Model, buildArea: BasePart)
	local gridPositionsToCFrame = {}
	local ordered = {}

	local amountOfX = math.ceil(buildArea.Size.X / GRID_SIZE)
	local amountOfZ = math.ceil(buildArea.Size.Z / GRID_SIZE)

	for i = 1, amountOfX * amountOfZ do
		local cellX = (i - 1) % amountOfX
		local cellZ = math.floor((i - 1) / amountOfX)

		local worldPosition = buildArea.CFrame.Position
			- Vector3.new(buildArea.Size.X / 2, 0, buildArea.Size.Z / 2)
			+ Vector3.new((cellX + 0.5) * GRID_SIZE, 0, (cellZ + 0.5) * GRID_SIZE)
		local gridPosition = Grid.getGridPosition(buildAreaModel, worldPosition)

		local stringValue = positionToString(gridPosition)
		gridPositionsToCFrame[stringValue] = CFrame.new(worldPosition)

		table.insert(ordered, gridPosition)
	end

	return gridPositionsToCFrame, ordered
end

function Grid.getAllCellCFrames(buildAreaModel: Model)
	local gridPositionsToCFrame = {}
	local ordered = {}

	local n = 1
	for _, buildArea in buildAreaModel:GetChildren() do
		local cellCFrames = Grid.getCellCFrames(buildAreaModel, buildArea)

		for gridPosition, cframe in cellCFrames do
			gridPositionsToCFrame[gridPosition] = cframe
			ordered[n] = {
				gridPosition = gridPosition,
				cframe = cframe,
			}

			n = n + 1
		end
	end

	return gridPositionsToCFrame, ordered
end

function Grid.getGridPosition(buildAreaModel: Model, position: Vector3)
	local buildAreaPivot, buildAreaSize = buildAreaModel:GetBoundingBox()

	-- add one so that the grid position is 1,1 instead of 0,0
	local gridPosition = Vector2.new(
		math.floor((position.X - buildAreaPivot.Position.X + buildAreaSize.X / 2) / GRID_SIZE) + 1,
		math.floor((position.Z - buildAreaPivot.Position.Z + buildAreaSize.Z / 2) / GRID_SIZE) + 1
	)

	return gridPosition
end

function Grid.stringToGridPosition(stringValue: string)
	local x, y = string.match(stringValue, "(-?%d+),(-?%d+)")
	return Vector2.new(tonumber(x), tonumber(y))
end

function Grid.positionToString(gridPosition: Vector2)
	return positionToString(gridPosition)
end

function Grid.getNearestGridPosition(buildAreaModel: Model, position: Vector3)
	local allCFrames = Grid.getAllCellCFrames(buildAreaModel)

	local nearestGridPosition = nil
	local nearestDistance = math.huge

	for gridPosition, cframe in allCFrames do
		local distance = (position - cframe.Position).Magnitude
		if distance < nearestDistance then
			nearestDistance = distance
			nearestGridPosition = gridPosition
		end
	end

	return nearestGridPosition
end

return Grid
