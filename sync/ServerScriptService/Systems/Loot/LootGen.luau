local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Knit = require(ReplicatedStorage.Packages.Knit)
local LootUtil = require(ReplicatedStorage.Utils.LootUtil)
local ServerScriptService = game:GetService("ServerScriptService")
local CrateSpawnUtil = require(ServerScriptService.Systems.Crate.CrateSpawnUtil)

local LootGen = Component.new({ Tag = "LootGen", Extensions = { TroveAdder, RemoteComponent } })

function LootGen:Construct() end

function LootGen:Start()
	self.Instance.Transparency = 1
	self.Instance.CanCollide = false
	self.Instance.Material = Enum.Material.SmoothPlastic
end

function LootGen:Generate()
	local rarity = CrateSpawnUtil.getCrateRarityFromInstance(self.Instance)
	local itemType, itemName = LootUtil.rollLoot(rarity)

	Knit.GetService("LootService"):CreateWorldLoot(itemName, itemType, self.Instance:GetPivot())
end

function LootGen:Stop() end

return LootGen
