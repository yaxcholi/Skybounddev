local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LootTables = require(ReplicatedStorage.Data.LootTables)
local ProcGenRandom = require(ReplicatedStorage.Utils.ProcGenRandom)

local LootUtil = {}

function LootUtil.rollLoot(crateRarity: string): (string, string)
	local entries = LootTables[crateRarity] or LootTables.Common
	local roll = ProcGenRandom.getLoot():NextNumber()
	local cumulative = 0

	for _, entry in entries do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.itemType, entry.itemName
		end
	end

	local fallback = entries[1]
	return fallback.itemType, fallback.itemName
end

function LootUtil.isCrateRarity(name: string): boolean
	return LootTables[name] ~= nil
end

return LootUtil
