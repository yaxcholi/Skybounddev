local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AmmoType = require(ReplicatedStorage.Enums.AmmoType)

return {
	[AmmoType.Pistol] = {
		Name = "Pistol Ammo",
		Description = "A pistol ammo type",
		Amount = 24,
	},
	[AmmoType.Rifle] = {
		Name = "Rifle Ammo",
		Description = "A rifle ammo type",
		Amount = 60,
	},
}
