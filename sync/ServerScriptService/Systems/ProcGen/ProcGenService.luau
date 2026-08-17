local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ProcGenConfig = require(ReplicatedStorage.Data.ProcGenConfig)
local ProcGenRandom = require(ReplicatedStorage.Utils.ProcGenRandom)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Trove = require(ReplicatedStorage.Packages.Trove)

local EnemyAirshipSpawner = require(script.Parent.EnemyAirshipSpawner)
local IslandPlacer = require(script.Parent.IslandPlacer)

local ProcGenTemplates = ServerStorage.ProcGen

export type Obstacle = IslandPlacer.Obstacle

local ProcGenService = Knit.CreateService({
	Name = "ProcGenService",
	Client = {},
})

local function segmentIntersectsObstacleXZ(
	fromPos: Vector3,
	toPos: Vector3,
	obstacle: Obstacle,
	margin: number
): boolean
	local localFrom = obstacle.cf:PointToObjectSpace(fromPos)
	local localTo = obstacle.cf:PointToObjectSpace(toPos)
	local halfSize = obstacle.size / 2 + Vector3.new(margin, margin, margin)

	local function axisOverlap(startPos: number, endPos: number, halfExtent: number): boolean
		local minPos = -halfExtent
		local maxPos = halfExtent
		local segMin = math.min(startPos, endPos)
		local segMax = math.max(startPos, endPos)
		return segMax >= minPos and segMin <= maxPos
	end

	if not axisOverlap(localFrom.X, localTo.X, halfSize.X) then
		return false
	end

	if not axisOverlap(localFrom.Z, localTo.Z, halfSize.Z) then
		return false
	end

	local delta = localTo - localFrom
	if math.abs(delta.X) < 1e-4 and math.abs(delta.Z) < 1e-4 then
		return math.abs(localFrom.X) <= halfSize.X and math.abs(localFrom.Z) <= halfSize.Z
	end

	local tValues = { 0, 1 }

	if math.abs(delta.X) > 1e-4 then
		table.insert(tValues, (-halfSize.X - localFrom.X) / delta.X)
		table.insert(tValues, (halfSize.X - localFrom.X) / delta.X)
	end

	if math.abs(delta.Z) > 1e-4 then
		table.insert(tValues, (-halfSize.Z - localFrom.Z) / delta.Z)
		table.insert(tValues, (halfSize.Z - localFrom.Z) / delta.Z)
	end

	for _, t in tValues do
		if t >= 0 and t <= 1 then
			local point = localFrom + delta * t
			if math.abs(point.X) <= halfSize.X and math.abs(point.Z) <= halfSize.Z then
				return true
			end
		end
	end

	return false
end

function ProcGenService:KnitInit()
	self._obstacles = {} :: { Obstacle }
	self._spawnedTowns = {} :: { [number]: boolean }
	self._segmentNextZ = {} :: { number }
	self._segmentStates = {} :: { IslandPlacer.PlacementState }
	self._nextCloudZ = 0
	self._nextEnemyAirshipZ = 0
	self._segments = {} :: { { phase: number, startZ: number, endZ: number, townZ: number } }
	self._islandSpawnOrder = 0
	self._generationTrove = Trove.new()
end

function ProcGenService:EnsureWorldFolders()
	local worldFolder = workspace:FindFirstChild("GeneratedWorld")
	if not worldFolder then
		worldFolder = Instance.new("Folder")
		worldFolder.Name = "GeneratedWorld"
		worldFolder.Parent = workspace
	end
	self._worldFolder = worldFolder

	local islandsFolder = worldFolder:FindFirstChild("Islands")
	if not islandsFolder then
		islandsFolder = Instance.new("Folder")
		islandsFolder.Name = "Islands"
		islandsFolder.Parent = worldFolder
	end
	self._islandsFolder = islandsFolder

	local cloudsFolder = worldFolder:FindFirstChild("Clouds")
	if not cloudsFolder then
		cloudsFolder = Instance.new("Folder")
		cloudsFolder.Name = "Clouds"
		cloudsFolder.Parent = worldFolder
	end
	self._cloudsFolder = cloudsFolder

	local enemyAirshipsFolder = worldFolder:FindFirstChild("EnemyAirships")
	if not enemyAirshipsFolder then
		enemyAirshipsFolder = Instance.new("Folder")
		enemyAirshipsFolder.Name = "EnemyAirships"
		enemyAirshipsFolder.Parent = worldFolder
	end
	self._enemyAirshipsFolder = enemyAirshipsFolder

	for _, child in islandsFolder:GetChildren() do
		if child:GetAttribute("IsTown") then
			local townZ = child:GetAttribute("TownZ")
			if townZ then
				self._spawnedTowns[townZ] = true
			end
		end
	end
end

function ProcGenService:HasTownAtZ(townZ: number): boolean
	if self._spawnedTowns[townZ] then
		return true
	end

	if not self._islandsFolder then
		return false
	end

	for _, child in self._islandsFolder:GetChildren() do
		if child:GetAttribute("IsTown") and child:GetAttribute("TownZ") == townZ then
			self._spawnedTowns[townZ] = true
			return true
		end
	end

	return false
end

function ProcGenService:KnitStart()
	ProcGenRandom.init(ProcGenConfig.SEED)

	self._generationTrove:Clean()

	local airshipService = Knit.GetService("AirshipService")
	local startZ = airshipService:GetTravelZ()

	self:EnsureWorldFolders()

	self._segments = {}
	local previousZ = startZ
	for phaseIndex, townZ in ProcGenConfig.TOWN_Z_POSITIONS do
		table.insert(self._segments, {
			phase = phaseIndex,
			startZ = previousZ,
			endZ = townZ,
			townZ = townZ,
		})

		if not self._segmentNextZ[phaseIndex] then
			self._segmentNextZ[phaseIndex] = previousZ
				- ProcGenRandom.get():NextNumber(ProcGenConfig.MIN_ISLAND_SPACING, ProcGenConfig.MAX_ISLAND_SPACING)
		end
		if not self._segmentStates[phaseIndex] then
			self._segmentStates[phaseIndex] = IslandPlacer.createPlacementState()
		end
		previousZ = townZ
	end

	if self._nextCloudZ == 0 then
		self._nextCloudZ = startZ - ProcGenConfig.CLOUD_Z_SPACING
	end
	if self._nextEnemyAirshipZ == 0 then
		self._nextEnemyAirshipZ = startZ - ProcGenConfig.ENEMY_AIRSHIP_Z_INTERVAL
	end

	self:TickGeneration(startZ)

	self._generationTrove:Add(Timer.Simple(1, function()
		self:TickGeneration(airshipService:GetTravelZ())
	end))
end

function ProcGenService:GetShipSpawnerTemplate(): Instance?
	local shipSpawners = ProcGenTemplates:FindFirstChild("ShipSpawners")
	if shipSpawners then
		local children = shipSpawners:GetChildren()
		if #children > 0 then
			return children[ProcGenRandom.get():NextInteger(1, #children)]
		end
	end

	return ProcGenTemplates:FindFirstChild("ShipSpawner")
end

function ProcGenService:GetNearbyObstacles(position: Vector3, radius: number): { Obstacle }
	local results = {}

	for _, obstacle in self._obstacles do
		if obstacle.instance.Parent then
			local offset = obstacle.cf.Position - position
			local reach = radius + obstacle.size.Magnitude * 0.5
			if offset:Dot(offset) <= reach * reach then
				table.insert(results, obstacle)
			end
		end
	end

	return results
end

function ProcGenService:GetSteeringTarget(fromPos: Vector3, targetPos: Vector3): Vector3
	local obstacles = self:GetNearbyObstacles(fromPos, 1200)
	local margin = ProcGenConfig.AVOIDANCE_MARGIN
	local blockingObstacle: Obstacle? = nil

	for _, obstacle in obstacles do
		if segmentIntersectsObstacleXZ(fromPos, targetPos, obstacle, margin) then
			blockingObstacle = obstacle
			break
		end
	end

	if not blockingObstacle then
		return targetPos
	end

	local halfX = blockingObstacle.size.X / 2 + margin
	local leftBypass = blockingObstacle.cf.Position.X - halfX
	local rightBypass = blockingObstacle.cf.Position.X + halfX
	local bypassX = if math.abs(fromPos.X - leftBypass) >= math.abs(fromPos.X - rightBypass)
		then leftBypass
		else rightBypass
	local midZ = (fromPos.Z + targetPos.Z) / 2

	return Vector3.new(bypassX, fromPos.Y, midZ)
end

function ProcGenService:SpawnTown(townZ: number)
	if self:HasTownAtZ(townZ) then
		return
	end

	local townsFolder = ProcGenTemplates:FindFirstChild("Towns")
	if not townsFolder then
		return
	end

	local children = townsFolder:GetChildren()
	if #children == 0 then
		return
	end

	self._spawnedTowns[townZ] = true

	local town = children[ProcGenRandom.get():NextInteger(1, #children)]:Clone()
	local airshipY = Knit.GetService("AirshipService"):GetTravelY()
	town:PivotTo(
		CFrame.new(ProcGenRandom.get():NextNumber(-15, 15), airshipY, townZ)
			* CFrame.Angles(0, math.rad(180), 0)
	)

	town:SetAttribute("IsTown", true)
	town:SetAttribute("TownZ", townZ)
	town:SetAttribute("SpawnZ", townZ)
	town.Parent = self._islandsFolder

	IslandPlacer.registerObstacle(town, self._obstacles)
end

function ProcGenService:TrySpawnIsland(segmentIndex: number, z: number)
	local segment = self._segments[segmentIndex]
	if not segment then
		return
	end

	local nextOrder = self._islandSpawnOrder + 1
	local island, newState = IslandPlacer.place(
		ProcGenRandom.get(),
		ProcGenTemplates,
		z,
		segment.phase,
		self._segmentStates[segmentIndex],
		self._islandsFolder,
		self._obstacles,
		nextOrder
	)

	if island then
		self._islandSpawnOrder = nextOrder
		self._segmentStates[segmentIndex] = newState
		self._segmentNextZ[segmentIndex] = z
	end
end

function ProcGenService:GenerateIslands(generateMinZ: number, generateMaxZ: number)
	for segmentIndex, segment in self._segments do
		local nextZ = self._segmentNextZ[segmentIndex]
		local segmentEndZ = segment.endZ + ProcGenConfig.MIN_ISLAND_SPACING

		while nextZ >= generateMinZ and nextZ <= generateMaxZ and nextZ >= segmentEndZ do
			self:TrySpawnIsland(segmentIndex, nextZ)

			local gap = ProcGenRandom.get():NextNumber(ProcGenConfig.MIN_ISLAND_SPACING, ProcGenConfig.MAX_ISLAND_SPACING)
			nextZ -= gap
			self._segmentNextZ[segmentIndex] = nextZ
		end
	end
end

function ProcGenService:SpawnCloud(z: number)
	local cloudTemplate = ProcGenTemplates:FindFirstChild("Clouds")
	if not cloudTemplate then
		return
	end

	local cluster = cloudTemplate:FindFirstChild("Cluster")
	if not cluster then
		return
	end

	local cloud = cluster:Clone()
	local isLeft = ProcGenRandom.get():NextNumber() < 0.5
	local xRange = isLeft and ProcGenConfig.CLOUD_X_RANGE.Left or ProcGenConfig.CLOUD_X_RANGE.Right

	cloud:PivotTo(
		CFrame.new(
			ProcGenRandom.get():NextNumber(xRange[1], xRange[2]),
			ProcGenRandom.get():NextNumber(ProcGenConfig.CLOUD_Y_RANGE[1], ProcGenConfig.CLOUD_Y_RANGE[2]),
			z
		) * CFrame.Angles(
			ProcGenRandom.get():NextNumber(0, math.pi * 2),
			ProcGenRandom.get():NextNumber(0, math.pi * 2),
			ProcGenRandom.get():NextNumber(0, math.pi * 2)
		)
	)

	cloud:SetAttribute("SpawnZ", z)
	cloud.Parent = self._cloudsFolder
end

function ProcGenService:GenerateClouds(generateMinZ: number, generateMaxZ: number)
	while self._nextCloudZ >= generateMinZ and self._nextCloudZ <= generateMaxZ do
		self:SpawnCloud(self._nextCloudZ)
		self._nextCloudZ -= ProcGenConfig.CLOUD_Z_SPACING
	end
end

function ProcGenService:GenerateEnemyAirships(generateMinZ: number, generateMaxZ: number, shipY: number)
	while self._nextEnemyAirshipZ >= generateMinZ and self._nextEnemyAirshipZ <= generateMaxZ do
		EnemyAirshipSpawner.trySpawn(
			ProcGenRandom.get(),
			self:GetShipSpawnerTemplate(),
			self._nextEnemyAirshipZ,
			shipY,
			self._enemyAirshipsFolder,
			self._obstacles
		)

		self._nextEnemyAirshipZ -= ProcGenConfig.ENEMY_AIRSHIP_Z_INTERVAL
	end
end

function ProcGenService:Cleanup(shipZ: number)
	local cleanupThreshold = shipZ + ProcGenConfig.CLEANUP_BEHIND

	for _, folder in { self._cloudsFolder, self._enemyAirshipsFolder } do
		for _, child in folder:GetChildren() do
			local spawnZ = child:GetAttribute("SpawnZ")
			if spawnZ and spawnZ > cleanupThreshold then
				child:Destroy()
			end
		end
	end

	for _, child in self._islandsFolder:GetChildren() do
		if child:GetAttribute("IsTown") then
			continue
		end

		local spawnZ = child:GetAttribute("SpawnZ")
		if spawnZ and spawnZ > cleanupThreshold then
			IslandPlacer.unregisterObstacle(child, self._obstacles)
			child:Destroy()
		end
	end
end

function ProcGenService:TickGeneration(shipZ: number)
	local generateMinZ = shipZ - ProcGenConfig.GENERATE_AHEAD
	local generateMaxZ = shipZ + ProcGenConfig.GENERATE_BEHIND_BUFFER

	for _, townZ in ProcGenConfig.TOWN_Z_POSITIONS do
		if townZ >= generateMinZ and townZ <= generateMaxZ then
			self:SpawnTown(townZ)
		end
	end

	self:GenerateIslands(generateMinZ, generateMaxZ)
	self:GenerateClouds(generateMinZ, generateMaxZ)
	self:GenerateEnemyAirships(generateMinZ, generateMaxZ, Knit.GetService("AirshipService"):GetTravelY())
	self:Cleanup(shipZ)
end

return ProcGenService
