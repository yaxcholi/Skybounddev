local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Interactable = require(ServerScriptService.Systems.Interactions.Interactable)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Cannon = Component.new({ Tag = "Cannon", Extensions = { TroveAdder, RemoteComponent } })
Cannon.Client = {
	Controller = Knit.CreateProperty(nil),
	UpdateTargetAngles = Knit.CreateSignal(),
	StopControl = Knit.CreateSignal(),
}

function Cannon:Construct()
	self._targetAngles = Vector2.zero

	self._pitchConstraint = self.Instance:FindFirstChild("PitchConstraint", true)
	self._yawConstraint = self.Instance:FindFirstChild("YawConstraint", true)
end

function Cannon:Start()
	local interaction = self.Instance:WaitForChild("Interaction")

	Interactable:WaitForInstance(interaction):andThen(function(interactable)
		self._trove:Add(interactable.OnInteract:Connect(function(player: Player)
			if self.Client.Controller:Get() then
				return
			end

			local character = player.Character

			if not character then
				return
			end

			local humanoid = character:FindFirstChild("Humanoid")
			if not humanoid then
				return
			end

			self.Client.Controller:Set(player)
		end))
	end)

	self._trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		if self.Client.Controller:Get() == player then
			self:SetOwner(nil)
		end
	end))

	self._trove:Add(self.Client.UpdateTargetAngles:Connect(function(player: Player, targetAngles: Vector2)
		if self.Client.Controller:Get() ~= player then
			return
		end

		self._targetAngles = targetAngles
	end))

	self._trove:Add(self.Client.StopControl:Connect(function(player: Player)
		if self.Client.Controller:Get() ~= player then
			return
		end

		self:SetOwner(nil)
	end))
end

function Cannon:SteppedUpdate()
	self._pitchConstraint.TargetAngle = -self._targetAngles.Y
	self._yawConstraint.TargetAngle = -self._targetAngles.X
end

function Cannon:SetOwner(player: Player?)
	if not player then
		self._targetAngles = Vector2.zero
		self.Client.Controller:Set(nil)
		return
	end

	if self.Client.Controller:Get() then
		return
	end

	self.Client.Controller:Set(player)
end

function Cannon:Stop() end

return Cannon
