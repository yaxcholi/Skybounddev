local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Scale = require(ReplicatedStorage.Scale)
local Timer = require(ReplicatedStorage.Packages.Timer)

local AirshipService = Knit.CreateService({
	Name = "AirshipService",
	Client = {
		TotalDistanceTraveled = Knit.CreateProperty(0),
	},
})

function AirshipService:KnitStart()
	local airship = self:GetPrimaryAirship()
	local startPosition = airship:GetPivot().Position

	Timer.Simple(0.2, function()
		local currentPosition = airship:GetPivot().Position
		local distanceStuds = startPosition.Z - currentPosition.Z
		local nauticalMiles = Scale.studsToNauticalMiles(distanceStuds)
		self.Client.TotalDistanceTraveled:Set(nauticalMiles)
	end)
end

function AirshipService:KnitInit() end

function AirshipService:GetTravelY(): number
	return self:GetPrimaryAirship():GetPivot().Position.Y
end

function AirshipService:GetTravelZ(): number
	return self:GetPrimaryAirship():GetPivot().Position.Z
end

function AirshipService:GetPrimaryAirship()
	local airship = CollectionService:GetTagged("PrimaryAirship")[1]

	repeat
		task.wait()
		airship = CollectionService:GetTagged("PrimaryAirship")[1]
	until airship

	return airship
end

return AirshipService
