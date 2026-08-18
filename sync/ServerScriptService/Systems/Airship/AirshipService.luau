local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Scale = require(ReplicatedStorage.Scale)
local Timer = require(ReplicatedStorage.Packages.Timer)

local AirshipService = Knit.CreateService({
	Name = "AirshipService",
	Client = {
		TotalDistanceTraveled = Knit.CreateProperty(0),
	},
})

function AirshipService:KnitInit() end

function AirshipService:KnitStart()
	local AirshipModule = require(ServerScriptService.Systems.Airship.Airship)
	local PrimaryAirship = self:GetPrimaryAirship()
	local StartPosition = PrimaryAirship:GetPivot().Position

	AirshipModule:WaitForInstance(PrimaryAirship):andThen(function(Airship)
		self._airshipComponent = Airship
	end)

	Timer.Simple(0.2, function()
		local CurrentPosition = PrimaryAirship:GetPivot().Position
		local DistanceStuds = StartPosition.Z - CurrentPosition.Z
		local NauticalMiles = Scale.studsToNauticalMiles(DistanceStuds)
		self.Client.TotalDistanceTraveled:Set(NauticalMiles)
	end)
end

function AirshipService:GetPrimaryAirship()
	local Airship = CollectionService:GetTagged("PrimaryAirship")[1]

	repeat
		task.wait()
		Airship = CollectionService:GetTagged("PrimaryAirship")[1]
	until Airship

	return Airship
end

function AirshipService:TakeDamage(Amount)
	if self._airshipComponent then
		self._airshipComponent:TakeDamage(Amount)
	end
end

function AirshipService:GetTravelY()
	return self:GetPrimaryAirship():GetPivot().Position.Y
end

function AirshipService:GetTravelZ()
	return self:GetPrimaryAirship():GetPivot().Position.Z
end

return AirshipService
