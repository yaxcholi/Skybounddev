--[[
	Deterministic procgen requires the same seed, ship path/speed, and unchanged
	Studio template child order (island spawners, town/cloud/airship folders).
]]
local ProcGenRandom = {}

local WORLD_STREAM_OFFSET = 1
local LOOT_STREAM_OFFSET = 2

local seed: number? = nil
local worldRandom: Random? = nil
local lootRandom: Random? = nil

function ProcGenRandom.init(configSeed: number?)
	if seed then
		return seed
	end

	if configSeed == nil then
		configSeed = Random.new():NextInteger(1, 2147483647)
	end

	seed = configSeed
	worldRandom = Random.new(seed + WORLD_STREAM_OFFSET)
	lootRandom = Random.new(seed + LOOT_STREAM_OFFSET)

	print("[SkyBound] ProcGen seed:", seed)

	return seed
end

function ProcGenRandom.getSeed(): number
	if not seed then
		ProcGenRandom.init(nil)
	end

	return seed :: number
end

function ProcGenRandom.get(): Random
	if not worldRandom then
		ProcGenRandom.init(nil)
	end

	return worldRandom :: Random
end

function ProcGenRandom.getLoot(): Random
	if not lootRandom then
		ProcGenRandom.init(nil)
	end

	return lootRandom :: Random
end

return ProcGenRandom
