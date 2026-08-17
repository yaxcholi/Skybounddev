local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage.Enums.Weapons)
local AmmoType = require(ReplicatedStorage.Enums.AmmoType)
local FireType = require(ReplicatedStorage.Enums.FireType)

return {
	[Weapons.Flintlock] = {
		Name = "Flintlock",
		Description = "A flintlock weapon",
		Damage = 20,
		Range = 100,
		ClipSize = 6,
		AmmoType = AmmoType.Pistol,
		FireType = FireType.SemiAuto,
	},
	[Weapons.LMG5] = {
		Name = "LMG5",
		Description = "A light machine gun",
		Damage = 30,
		Range = 200,
		ClipSize = 30,
		AmmoType = AmmoType.Rifle,
		FireType = FireType.FullAuto,
	},
}