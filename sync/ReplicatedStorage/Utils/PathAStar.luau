-- https://www.lualearning.org/tutorials/B486CA21-E02C-4A9A-BD8C-BE27329663F8/custom-pathfinding-with-a

-- Supports irregular (ragged) grids where each column x can have a different height (#worldGrid[x]).
-- worldGrid[x][y] is the traversal cost for that cell (numbers). Missing cells are simply absent.

local function manhattanDistance(node, goalNode)
	local xDist = math.abs(goalNode.coord.X - node.coord.X)
	local yDist = math.abs(goalNode.coord.Y - node.coord.Y)
	return xDist + yDist
end

local function CalculatePath(worldGrid, start, goal)
	-- Helper: height of a given column (x). 0 if column missing.
	local function colHeight(x)
		local col = worldGrid[x]
		if type(col) == "table" then
			return #col
		end
		return 0
	end

	local WIDTH = #worldGrid

	-- Validate start/goal bounds against *their own columns*
	assert(start.X >= 1 and start.X <= WIDTH, "Start X is out of bounds")
	assert(goal.X >= 1 and goal.X <= WIDTH, "Goal X is out of bounds")

	local startColH = colHeight(start.X)
	local goalColH = colHeight(goal.X)
	assert(startColH > 0, ("Start column %d is empty"):format(start.X))
	assert(goalColH > 0, ("Goal column %d is empty"):format(goal.X))
	assert(start.Y >= 1 and start.Y <= startColH, "Start Y is out of bounds for its column")
	assert(goal.Y >= 1 and goal.Y <= goalColH, "Goal Y is out of bounds for its column")

	-- A* state
	local nodeSet = {}
	local openSet = {}
	local cameFrom = {}
	local costSoFar = {}
	local path = {}
	local winnerNode = nil

	-- Build nodeSet only for existing cells
	for x = 1, WIDTH do
		nodeSet[x] = {}
		local h = colHeight(x)
		for y = 1, h do
			-- Skip holes if any entry is nil (optional safeguard)
			if worldGrid[x][y] ~= nil then
				nodeSet[x][y] = {
					coord = Vector2.new(x, y),
					cost = worldGrid[x][y],
					f = nil,
				}
			end
		end
	end

	-- Start/Goal nodes must exist
	local startNode = nodeSet[start.X] and nodeSet[start.X][start.Y]
	local goalNode = nodeSet[goal.X] and nodeSet[goal.X][goal.Y]
	assert(startNode, "Start cell is not present (hole or nil)")
	assert(goalNode, "Goal cell is not present (hole or nil)")

	-- Validity for a specific (x,y): column must exist, y within its height, and the cell must not be nil
	local function isValid(x, y)
		if x < 1 or x > WIDTH then
			return false
		end
		local h = colHeight(x)
		if y < 1 or y > h then
			return false
		end
		if nodeSet[x][y] == nil then
			return false
		end
		return true
	end

	local function getNeighbors(node)
		local neighbors = {}
		local x, y = node.coord.X, node.coord.Y

		-- Horizontal neighbors: only if target column has row y
		if isValid(x - 1, y) then
			table.insert(neighbors, nodeSet[x - 1][y])
		end
		if isValid(x + 1, y) then
			table.insert(neighbors, nodeSet[x + 1][y])
		end

		-- Vertical neighbors: within same column
		if isValid(x, y - 1) then
			table.insert(neighbors, nodeSet[x][y - 1])
		end
		if isValid(x, y + 1) then
			table.insert(neighbors, nodeSet[x][y + 1])
		end

		return neighbors
	end

	-- Insert into openSet sorted by f
	local function putInOpenSet(node, newCost)
		node.f = newCost + manhattanDistance(node, goalNode)
		for i, existingNode in ipairs(openSet) do
			if node.f < existingNode.f then
				table.insert(openSet, i, node)
				return
			end
		end
		table.insert(openSet, node)
	end

	-- Initialize
	costSoFar[startNode] = 0
	openSet[1] = startNode

	-- Main A*
	while #openSet > 0 do
		local currentNode = openSet[1]
		table.remove(openSet, 1)

		if currentNode.coord.X == goal.X and currentNode.coord.Y == goal.Y then
			winnerNode = currentNode
			break
		end

		for _, neighbor in ipairs(getNeighbors(currentNode)) do
			local newCost = costSoFar[currentNode] + neighbor.cost
			if not costSoFar[neighbor] or newCost < costSoFar[neighbor] then
				costSoFar[neighbor] = newCost
				putInOpenSet(neighbor, newCost)
				cameFrom[neighbor] = currentNode
			end
		end
	end

	-- No path found
	if not winnerNode then
		return nil
	end

	-- Reconstruct path (excluding the start cell, like the original)
	while winnerNode ~= startNode do
		table.insert(path, 1, winnerNode.coord)
		winnerNode = cameFrom[winnerNode]
	end

	return path
end

return CalculatePath
