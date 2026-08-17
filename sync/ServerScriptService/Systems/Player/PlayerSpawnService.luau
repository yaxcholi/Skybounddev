local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PlayerSpawnService = Knit.CreateService({
	Name = "PlayerSpawnService",
	Client = {},
})

function PlayerSpawnService:KnitStart()
	Observers.observePlayer(function(player: Player)
		player:LoadCharacterAsync()
	end)

	Observers.observeCharacter(function(player: Player, character: Model)
		local trove = Trove.new()

		trove:Add(character.ChildRemoved:Connect(function()
			for _, child in character:GetChildren() do
				if child:IsA("BasePart") then
					return
				end
			end

			Knit.GetService("ReviveService"):RespawnDeadPlayer(player)
		end))

		return function()
			trove:Destroy()
		end
	end)
end

function PlayerSpawnService:KnitInit() end

return PlayerSpawnService
