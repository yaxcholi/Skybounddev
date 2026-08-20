local ContractConfig = {}

ContractConfig.FACTION_ORDER = { "Greed", "Fighting", "Cowardice" }

ContractConfig.TIER_FLOOR = 1
ContractConfig.TIER_CEILING_BONUS = 2

ContractConfig.FACTION_COLORS = {
	Greed = Color3.fromRGB(110, 18, 18),
	Fighting = Color3.fromRGB(20, 75, 28),
	Cowardice = Color3.fromRGB(18, 58, 95),
}

ContractConfig.Contracts = {
	Greed = {
		[1] = {
			stars = 1, dangerStars = 1,
			destination = "",
			description = "",
			bonus = { { name = "Coin Chest", quantity = 2 } },
			modifiers = { enemyFrequencyMultiplier = 1.0 },
		},
		[2] = {
			stars = 2, dangerStars = 1,
			destination = "",
			description = "",
			bonus = { { name = "Coin Chest", quantity = 3 } },
			modifiers = { enemyFrequencyMultiplier = 1.2 },
		},
		[3] = {
			stars = 2, dangerStars = 2,
			destination = "",
			description = "",
			bonus = { { name = "Coin Chest", quantity = 4 }, { name = "Flintlock", quantity = 1 } },
			modifiers = { enemyFrequencyMultiplier = 1.5 },
		},
		[4] = {
			stars = 3, dangerStars = 2,
			destination = "",
			description = "",
			bonus = { { name = "Coin Chest", quantity = 6 }, { name = "Flintlock", quantity = 1 } },
			modifiers = { enemyFrequencyMultiplier = 1.8 },
		},
		[5] = {
			stars = 3, dangerStars = 3,
			destination = "",
			description = "",
			bonus = { { name = "Coin Chest", quantity = 8 }, { name = "Coin Chest", quantity = 4 } },
			modifiers = { enemyFrequencyMultiplier = 2.2 },
		},
	},
	Fighting = {
		[1] = {
			stars = 1, dangerStars = 1,
			destination = "",
			description = "",
			bonus = { { name = "Flintlock", quantity = 2 } },
			modifiers = { enemyFrequencyMultiplier = 1.2 },
		},
		[2] = {
			stars = 1, dangerStars = 2,
			destination = "",
			description = "",
			bonus = { { name = "Flintlock", quantity = 2 }, { name = "Bandage", quantity = 3 } },
			modifiers = { enemyFrequencyMultiplier = 1.5 },
		},
		[3] = {
			stars = 2, dangerStars = 2,
			destination = "",
			description = "",
			bonus = { { name = "Flintlock", quantity = 3 }, { name = "Bandage", quantity = 4 } },
			modifiers = { enemyFrequencyMultiplier = 1.8 },
		},
		[4] = {
			stars = 2, dangerStars = 3,
			destination = "",
			description = "",
			bonus = { { name = "Flintlock", quantity = 4 }, { name = "Bandage", quantity = 5 } },
			modifiers = { enemyFrequencyMultiplier = 2.0 },
		},
		[5] = {
			stars = 2, dangerStars = 4,
			destination = "",
			description = "",
			bonus = { { name = "Flintlock", quantity = 5 }, { name = "Bandage", quantity = 6 } },
			modifiers = { enemyFrequencyMultiplier = 2.5 },
		},
	},
	Cowardice = {
		[1] = {
			stars = 2, dangerStars = 0,
			weather = "Lightning",
			destination = "",
			description = "",
			bonus = { { name = "Bandage", quantity = 6 } },
			modifiers = { enemyFrequencyMultiplier = 0.5 },
		},
		[2] = {
			stars = 2, dangerStars = 1,
			weather = "Lightning",
			destination = "",
			description = "",
			bonus = { { name = "Bandage", quantity = 8 } },
			modifiers = { enemyFrequencyMultiplier = 0.6 },
		},
		[3] = {
			stars = 3, dangerStars = 1,
			weather = "Lightning",
			destination = "",
			description = "",
			bonus = { { name = "Bandage", quantity = 10 }, { name = "Coin Chest", quantity = 1 } },
			modifiers = { enemyFrequencyMultiplier = 0.7 },
		},
		[4] = {
			stars = 3, dangerStars = 2,
			weather = "Lightning",
			destination = "",
			description = "",
			bonus = { { name = "Bandage", quantity = 12 }, { name = "Coin Chest", quantity = 2 } },
			modifiers = { enemyFrequencyMultiplier = 0.8 },
		},
		[5] = {
			stars = 4, dangerStars = 2,
			weather = "Lightning",
			destination = "",
			description = "",
			bonus = { { name = "Bandage", quantity = 15 }, { name = "Coin Chest", quantity = 3 } },
			modifiers = { enemyFrequencyMultiplier = 0.9 },
		},
	},
}

function ContractConfig.GetContract(faction: string, tier: number)
	local contracts = ContractConfig.Contracts[faction]
	return contracts[math.clamp(tier, 1, #contracts)]
end

return ContractConfig
