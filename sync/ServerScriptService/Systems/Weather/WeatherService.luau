local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local WeatherService = Knit.CreateService({
	Name = "WeatherService",
	Client = {
		Weather = Knit.CreateProperty("None"),
	},
})

function WeatherService:KnitInit() end
function WeatherService:KnitStart() end

function WeatherService:SetWeather(weatherType: string)
	self.Client.Weather:Set(weatherType)
end

return WeatherService