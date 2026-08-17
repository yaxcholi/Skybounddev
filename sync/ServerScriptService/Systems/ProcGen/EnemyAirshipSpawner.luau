local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProcGenConfig = require(ReplicatedStorage.Data.ProcGenConfig)
local IslandPlacer = require(script.Parent.IslandPlacer)

export type Obstacle = IslandPlacer.Obstacle

local EnemyAirshipSpawner = {}

local function pointInObstacle(position: Vector3, obstacle: Obstacle, margin: number): boolean
	local localPos = obstacle.cf:PointToObjectSpace(position)
	local halfSize = obstacle.size / 2 + Vector3.one * margin

	return math.abs(localPos.X) <= halfSize.X
		and math.abs(localPos.Y) <= halfSize.Y
		and math.abs(localPos.Z) <= halfSize.Z
end

function EnemyAirshipSpawner.isPositionClear(position: Vector3, obstacles: { Obstacle }, margin: number): boolean
	for _, obstacle in obstacles do
		if obstacle.instance.Parent and pointInObstacle(position, obstacle, margin) then
			return false
		end
	end

	return true
end

function EnemyAirshipSpawner.trySpawn(
	random: Random,
	template: Instance?,
	z: number,
	spawnY: number,
	parent: Instance,
	obstacles: { Obstacle }
): Model?
	if not template then
		return nil
	end

	local isLeft = random:NextNumber() < 0.5
	local xRange = isLeft and ProcGenConfig.ENEMY_AIRSHIP_X_RANGE.Left or ProcGenConfig.ENEMY_AIRSHIP_X_RANGE.Right

	for _ = 1, 6 do
		local xOffset = random:NextNumber(xRange[1], xRange[2])
		local position = Vector3.new(xOffset, spawnY, z)

		if EnemyAirshipSpawner.isPositionClear(position, obstacles, ProcGenConfig.AVOIDANCE_MARGIN) then
			local airship = template:Clone()
			airship:PivotTo(CFrame.new(position) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0))
			airship:SetAttribute("SpawnZ", z)
			airship.Parent = parent
			return airship
		end
	end

	return nil
end

return EnemyAirshipSpawner
