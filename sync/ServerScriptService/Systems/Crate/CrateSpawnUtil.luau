local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProcGenConfig = require(ReplicatedStorage.Data.ProcGenConfig)
local LootUtil = require(ReplicatedStorage.Utils.LootUtil)
local ProcGenRandom = require(ReplicatedStorage.Utils.ProcGenRandom)

local CrateSpawnUtil = {}

function CrateSpawnUtil.getIslandAncestor(instance: Instance): Model?
	local current: Instance? = instance
	while current do
		if current:GetAttribute("IslandTier") then
			return current :: Model
		end
		current = current.Parent
	end

	return nil
end

function CrateSpawnUtil.getIslandTier(instance: Instance): string
	local island = CrateSpawnUtil.getIslandAncestor(instance)
	if island then
		return island:GetAttribute("IslandTier") or "Small"
	end

	return "Small"
end

function CrateSpawnUtil.rollCrateRarity(tier: string): string
	local weights = ProcGenConfig.CRATE_RARITY_WEIGHTS_BY_TIER[tier]
		or ProcGenConfig.CRATE_RARITY_WEIGHTS_BY_TIER.Small
	local roll = ProcGenRandom.get():NextNumber()
	local cumulative = 0

	for _, rarity in ProcGenConfig.CRATE_RARITIES do
		cumulative += weights[rarity] or 0
		if roll <= cumulative then
			return rarity
		end
	end

	return "Common"
end

function CrateSpawnUtil.getCrateTemplate(cratesFolder: Instance, tier: string): Model?
	local rarity = CrateSpawnUtil.rollCrateRarity(tier)
	local template = cratesFolder:FindFirstChild(rarity)

	if not template then
		warn(`CrateSpawnUtil: missing crate template "{rarity}"`)
	end

	return template :: Model?
end

function CrateSpawnUtil.getCrateRarityFromInstance(instance: Instance): string
	local current: Instance? = instance
	while current do
		local rarity = current:GetAttribute("CrateRarity")
		if rarity then
			return rarity
		end

		if LootUtil.isCrateRarity(current.Name) then
			return current.Name
		end

		current = current.Parent
	end

	return "Common"
end

return CrateSpawnUtil
