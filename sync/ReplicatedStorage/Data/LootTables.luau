local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AmmoType = require(ReplicatedStorage.Enums.AmmoType)
local Weapons = require(ReplicatedStorage.Enums.Weapons)

export type LootEntry = {
	itemType: string,
	itemName: string,
	weight: number,
}

local LootTables = {}

LootTables.Common = {
	{ itemType = "Weapon", itemName = Weapons.Flintlock, weight = 0.15 },
	{ itemType = "AmmoType", itemName = AmmoType.Pistol, weight = 0.425 },
	{ itemType = "AmmoType", itemName = AmmoType.Rifle, weight = 0.425 },
}

LootTables.Uncommon = {
	{ itemType = "Weapon", itemName = Weapons.Flintlock, weight = 0.30 },
	{ itemType = "Weapon", itemName = Weapons.LMG5, weight = 0.05 },
	{ itemType = "AmmoType", itemName = AmmoType.Pistol, weight = 0.325 },
	{ itemType = "AmmoType", itemName = AmmoType.Rifle, weight = 0.325 },
}

LootTables.Rare = {
	{ itemType = "Weapon", itemName = Weapons.Flintlock, weight = 0.20 },
	{ itemType = "Weapon", itemName = Weapons.LMG5, weight = 0.35 },
	{ itemType = "AmmoType", itemName = AmmoType.Pistol, weight = 0.225 },
	{ itemType = "AmmoType", itemName = AmmoType.Rifle, weight = 0.225 },
}

LootTables.Legendary = {
	{ itemType = "Weapon", itemName = Weapons.Flintlock, weight = 0.10 },
	{ itemType = "Weapon", itemName = Weapons.LMG5, weight = 0.70 },
	{ itemType = "AmmoType", itemName = AmmoType.Pistol, weight = 0.10 },
	{ itemType = "AmmoType", itemName = AmmoType.Rifle, weight = 0.10 },
}

return LootTables
