local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Knit = require(ReplicatedStorage.Packages.Knit)
local LootUtil = require(ReplicatedStorage.Utils.LootUtil)
local ServerScriptService = game:GetService("ServerScriptService")
local CrateSpawnUtil = require(ServerScriptService.Systems.Crate.CrateSpawnUtil)

local SURFACE_RAYCAST_DISTANCE = 10

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
	local pivot = self.Instance:GetPivot()

	local model = Knit.GetService("LootService"):CreateWorldLoot(itemName, itemType, pivot)

	local handle = model.PrimaryPart
	if handle then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { model }

		local result = workspace:Raycast(pivot.Position, Vector3.new(0, -SURFACE_RAYCAST_DISTANCE, 0), raycastParams)
		if result and result.Instance:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = result.Instance
			weld.Part1 = handle
			weld.Parent = handle
		end
	end
end

function LootGen:Stop() end

return LootGen
