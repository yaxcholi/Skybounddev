local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Input = require(ReplicatedStorage.Packages.Input)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)

local keyboard = Input.Keyboard.new()

local CanBeDropped = Component.new({ Tag = "CanBeDropped", Extensions = { TroveAdder, RemoteComponent } })

function CanBeDropped:Construct() end

function CanBeDropped:Start()
	self._trove:Add(keyboard.KeyDown:Connect(function(keyCode)
		
		if keyCode ~= Enum.KeyCode.Backspace then
			return
		end

		print(`Dropping {keyCode}`)

		local character = Players.LocalPlayer.Character
		if not character or self.Instance.Parent ~= character then
			return
		end

		print(`Dropping`)
		self.Server.Drop:Fire()
	end))
end

function CanBeDropped:Stop() end

return CanBeDropped
