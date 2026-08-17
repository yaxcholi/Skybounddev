local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PlayerCollisionService = Knit.CreateService {
	Name = "PlayerCollisionService";
	Client = {};
}


function PlayerCollisionService:KnitStart()
	Observers.observeCharacter(function(_, character: Model)
		local trove = Trove.new()

		for _,v in character:GetDescendants() do
			if not v:IsA("BasePart") then
				continue
			end

			v.CollisionGroup = "Players"
		end

		trove:Add(character.DescendantAdded:Connect(function(v: Instance)
			if not v:IsA("BasePart") then
				return
			end
			
			v.CollisionGroup = "Players"
		end))

		return function ()
			trove:Destroy()
		end
	end)
end


function PlayerCollisionService:KnitInit()
	
end


return PlayerCollisionService
