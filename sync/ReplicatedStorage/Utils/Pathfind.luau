local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Grid = require(ReplicatedStorage.Grid)
local PathAStar = require(ReplicatedStorage.Utils.PathAStar)

local cache = {}
return function(plot: Model, start: Vector2, goal: Vector2)
	local buildArea = plot:FindFirstChild("BuildArea")

	local globalNodes: { [string]: CFrame } = cache[plot] and cache[plot].globalNodes or {}
	local columns: { [number]: { [number]: { key: string, cframe: CFrame, cost: number } } } = cache[plot]
			and cache[plot].columns
		or {}
	local maxX, maxZ = cache[plot] and cache[plot].maxX or 0, cache[plot] and cache[plot].maxZ or 0

	if not cache[plot] then
		for _, cframe in Grid.getAllCellCFrames(buildArea) do
			local gp = Grid.getGridPosition(buildArea, cframe.Position) -- Vector2 (X,Z or X,Y)
			local x, z = gp.X, gp.Y

			local key = `{x},{z}`
			globalNodes[key] = cframe

			columns[x] = columns[x] or {}
			-- You can compute cost per cell here (terrain, etc.). Default 1:
			columns[x][z] = { key = key, cframe = cframe, cost = 1 }

			if x > maxX then
				maxX = x
			end
			if z > maxZ then
				maxZ = z
			end
		end
	end

	cache[plot] = {
		globalNodes = globalNodes,
		columns = columns,
		maxX = maxX,
		maxZ = maxZ,
	}

	-- Now build ragged arrays with holes left as nil
	local aStarNodes: { { string? } } = table.create(maxX)
	local aStarCosts: { { number? } } = table.create(maxX)

	for x = 1, maxX do
		local col = columns[x]
		if col then
			-- find this column's tallest z
			local maxZx = 0
			for z, _ in pairs(col) do
				if z > maxZx then
					maxZx = z
				end
			end

			local nodesCol = table.create(maxZx)
			local costsCol = table.create(maxZx)
			for z = 1, maxZx do
				local cell = col[z]
				if cell then
					nodesCol[z] = cell.key
					costsCol[z] = cell.cost
				else
					-- hole: leave nil (blocked/nonexistent)
					nodesCol[z] = nil
					costsCol[z] = nil
				end
			end

			aStarNodes[x] = nodesCol
			aStarCosts[x] = costsCol
		else
			-- whole column missing -> keep as empty table
			aStarNodes[x] = {}
			aStarCosts[x] = {}
		end
	end

	local bestPath = PathAStar(aStarCosts, start, goal)
	if not bestPath then
		return {}
	end
	table.insert(bestPath, 1, start)

	local cframes = {}

	for _, position in bestPath do
		local node = aStarNodes[position.X][position.Y]
		table.insert(cframes, globalNodes[node])
	end

	return cframes
end
