local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local HoldInteractable = Component.new({ Tag = "HoldInteractable", Extensions = { TroveAdder, RemoteComponent } })
HoldInteractable.Client = {
	OnHoldComplete = Knit.CreateSignal(),
}

function HoldInteractable:Construct()
	self.OnHoldComplete = Signal.new()
end

function HoldInteractable:Start()
	self._trove:Add(self.Client.OnHoldComplete:Connect(function(player: Player)
		self:CompleteHold(player)
	end))
end

function HoldInteractable:IsEnabled(): boolean
	return self.Instance:GetAttribute("Enabled") ~= false
end

function HoldInteractable:CompleteHold(player: Player)
	if not self:IsEnabled() then
		return
	end

	if not player.Character then
		return
	end

	self.OnHoldComplete:Fire(player)
end

function HoldInteractable:Stop() end

return HoldInteractable
