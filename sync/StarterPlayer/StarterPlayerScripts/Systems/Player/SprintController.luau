local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")	
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)

local SprintController = Knit.CreateController { Name = "SprintController" }


function SprintController:KnitStart()
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if input.KeyCode ~= Enum.KeyCode.LeftShift then
			return
		end

		local character = Players.LocalPlayer.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		humanoid.WalkSpeed = 24
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if input.KeyCode ~= Enum.KeyCode.LeftShift then
			return
		end

		local character = Players.LocalPlayer.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
	end)
end


function SprintController:KnitInit()
	
end


return SprintController
