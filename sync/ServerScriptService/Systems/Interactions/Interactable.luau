local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Interactable = Component.new({ Tag = "Interactable", Extensions = { TroveAdder, RemoteComponent } })
Interactable.Client = {
	OnInteract = Knit.CreateSignal(),
}

function Interactable:Construct()
	self.OnInteract = Signal.new()
	if self.Instance:GetAttribute("Enabled") == nil then
		self.Instance:SetAttribute("Enabled", true)
	end
end

function Interactable:Start()
	self._trove:Add(self.Client.OnInteract:Connect(function(player: Player)
		self:Interact(player)
	end))
end

function Interactable:Interact(player: Player)
	if not self:IsEnabled() then
		return
	end

	self.OnInteract:Fire(player)
end

function Interactable:SetEnabled(enabled: boolean)
	self.Instance:SetAttribute("Enabled", enabled)
end

function Interactable:IsEnabled(): boolean
	return self.Instance:GetAttribute("Enabled") ~= false
end

function Interactable:Stop() end

return Interactable
