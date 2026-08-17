local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Observers = require(ReplicatedStorage.Packages.Observers)

local JetpackService = Knit.CreateService({
	Name = "JetpackService",
	Client = {},
})

function JetpackService:KnitStart()
	Observers.observeCharacter(function(_, character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid

		local newJetpack = ServerStorage.Assets.Jetpack:Clone()
		humanoid:AddAccessory(newJetpack)
		newJetpack:AddTag("Jetpack")
	end)
end

function JetpackService:KnitInit() end

return JetpackService
