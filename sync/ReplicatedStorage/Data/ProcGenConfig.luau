local ProcGenConfig = {}

-- Set to a number for deterministic worlds; nil picks a random seed each session
ProcGenConfig.SEED = nil

ProcGenConfig.TOWN_Z_POSITIONS = {-1000, -5000, -10000, -15000}

ProcGenConfig.MIN_ISLAND_SPACING = 120
ProcGenConfig.MAX_ISLAND_SPACING = 220
ProcGenConfig.GENERATE_AHEAD = 2500
ProcGenConfig.CLEANUP_BEHIND = 2000
ProcGenConfig.GENERATE_BEHIND_BUFFER = 200

ProcGenConfig.ISLAND_X_RANGE_BY_TIER = {
	Small = {
		Left = { -170, -100 },
		Right = { 100, 170 },
	},
	Medium = {
		Left = { -220, -150 },
		Right = { 150, 220 },
	},
	Large = {
		Left = { -280, -180 },
		Right = { 180, 280 },
	},
}

ProcGenConfig.ISLAND_Y_RANGE = { 5, 50 }

ProcGenConfig.SIZE_WEIGHTS = {
	Small = 0.50,
	Medium = 0.35,
	Large = 0.15,
}

ProcGenConfig.PHASE_SIZE_WEIGHTS = {
	[1] = { Small = 0.55, Medium = 0.30, Large = 0.15 },
	[2] = { Small = 0.45, Medium = 0.35, Large = 0.20 },
	[3] = { Small = 0.35, Medium = 0.35, Large = 0.30 },
}

ProcGenConfig.ENEMY_AIRSHIP_Z_INTERVAL = 350
ProcGenConfig.ENEMY_AIRSHIP_X_RANGE = {
	Left = { -800, -450 },
	Right = { 450, 800 },
}

ProcGenConfig.AVOIDANCE_MARGIN = 100

ProcGenConfig.CLOUD_X_RANGE = {
	Left = { -600, -300 },
	Right = { 300, 600 },
}
ProcGenConfig.CLOUD_Y_RANGE = { -100, 100 }
ProcGenConfig.CLOUD_Z_SPACING = 150

ProcGenConfig.CRATE_RARITIES = { "Common", "Uncommon", "Rare", "Legendary" }

ProcGenConfig.CRATE_RARITY_WEIGHTS_BY_TIER = {
	Small = {
		Common = 0.70,
		Uncommon = 0.22,
		Rare = 0.07,
		Legendary = 0.01,
	},
	Medium = {
		Common = 0.50,
		Uncommon = 0.30,
		Rare = 0.15,
		Legendary = 0.05,
	},
	Large = {
		Common = 0.30,
		Uncommon = 0.35,
		Rare = 0.25,
		Legendary = 0.10,
	},
}

ProcGenConfig.NPC_WEIGHTS_BY_TIER = {
	Small = {
		MeleeGrunt = 0.70,
		RangedGrunt = 0.30,
	},
	Medium = {
		MeleeGrunt = 0.50,
		RangedGrunt = 0.50,
	},
	Large = {
		MeleeGrunt = 0.30,
		RangedGrunt = 0.70,
	},
}

ProcGenConfig.CRATE_SPAWN_CHANCE_BY_TIER = {
	Small = 0.25,
	Medium = 0.40,
	Large = 0.55,
}

return ProcGenConfig
