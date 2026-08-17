local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local FadeUI = require(script.Parent.FadeUI)

local FadeController = Knit.CreateController({ Name = "FadeController" })

function FadeController:KnitStart() end

function FadeController:KnitInit() end

function FadeController:FadeIn()
	for _, fadeUI in FadeUI:GetAll() do
		fadeUI:FadeIn()
	end

	task.wait(1)
end

function FadeController:FadeOut()
	for _, fadeUI in FadeUI:GetAll() do
		fadeUI:FadeOut()
	end

	task.wait(0.5)
end

return FadeController
