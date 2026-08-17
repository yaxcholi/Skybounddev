local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Collectable = Component.new({ Tag = "Collectable", Extensions = { TroveAdder, RemoteComponent } })
Collectable.Client = {
	OnInteract = Knit.CreateSignal(),
}

function Collectable:Construct()
	self.OnInteract = Signal.new()
end

function Collectable:Start()
	self._trove:Add(self.Client.OnInteract:Connect(function(player: Player)
		self:Interact(player)
	end))
end

function Collectable:Interact(player: Player)
	if not player.Character then
		return
	end

	local itemName = self.Instance:GetAttribute("ItemName")
	local itemType = self.Instance:GetAttribute("Type")
	local ammoAmount = self.Instance:GetAttribute("AmmoAmount")
	local currentClip = self.Instance:GetAttribute("CurrentClip")

	self.Instance:Destroy()

	local tool = ServerStorage.Assets.Tools:FindFirstChild(itemName)
	if not tool then
		error(`Tool {itemName} not found`)
		return
	end

	local existingTool = player.Character:FindFirstChildWhichIsA("Tool")
	if existingTool then
		existingTool.Parent = player.Backpack
	end

	local clone = tool:Clone()
	clone:SetAttribute("ItemName", itemName)
	clone:SetAttribute("Type", itemType)
	if itemType == "AmmoType" then
		local lootService = Knit.GetService("LootService")
		local resolvedAmmoAmount = ammoAmount
		if resolvedAmmoAmount == nil then
			resolvedAmmoAmount = lootService:GetDefaultAmmoAmount(itemName)
		end

		clone:SetAttribute("AmmoAmount", resolvedAmmoAmount)
	elseif itemType == "Weapon" and currentClip ~= nil then
		clone:SetAttribute("CurrentClip", currentClip)
	end
	clone:AddTag("CanBeDropped")
	clone.CanBeDropped = false -- disable roblox default drop functionality
	clone.Parent = player.Character
end

function Collectable:Stop() end

return Collectable
