local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)

local LocalPlayer = Players.LocalPlayer

local Airship = Component.new({ Tag = "PrimaryAirship", Extensions = { TroveAdder, RemoteComponent } })

function Airship:Construct()
end

function Airship:Start()
	local Seat = self.Instance:FindFirstChild("AirshipSeat")

	self._trove:Add(UserInputService.InputBegan:Connect(function(Input, Processed)
		if Processed then
			return
		end
		if not Seat or Seat.Occupant ~= LocalPlayer.Character:FindFirstChild("Humanoid") then
			return
		end
		if Input.KeyCode == Enum.KeyCode.Z then
			self.Server.AdjustAltitude:Fire(1)
		elseif Input.KeyCode == Enum.KeyCode.X then
			self.Server.AdjustAltitude:Fire(-1)
		end
	end))
end

function Airship:Stop()
end

return Airship
