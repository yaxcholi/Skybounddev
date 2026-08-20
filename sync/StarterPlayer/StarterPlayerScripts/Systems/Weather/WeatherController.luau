local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Knit = require(ReplicatedStorage.Packages.Knit)
local WeatherConfig = require(ReplicatedStorage.Data.WeatherConfig)

local TWEEN_TIME = 3

local WeatherController = Knit.CreateController({ Name = "WeatherController" })

local _lightningThread = nil

local function stopLightning()
	if _lightningThread then
		task.cancel(_lightningThread)
		_lightningThread = nil
	end
end

local function startLightning(cfg)
	stopLightning()
	_lightningThread = task.spawn(function()
		local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
		if not cc then return end
		while true do
			task.wait(math.random(cfg.lightningInterval.min, cfg.lightningInterval.max))
			local base = cc.Brightness
			for _ = 1, 2 do
				cc.Brightness = cfg.lightningFlashBrightness
				task.wait(cfg.lightningFlashDuration)
				cc.Brightness = base
				task.wait(0.05)
			end
		end
	end)
end

local function applyWeather(weatherType: string)
	local cfg = WeatherConfig.Types[weatherType] or WeatherConfig.Types.None
	local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine)

	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")

	if cc then
		TweenService:Create(cc, tweenInfo, cfg.colorCorrection):Play()
	end
	if atmo then
		TweenService:Create(atmo, tweenInfo, cfg.atmosphere):Play()
	end
	if sunRays then
		sunRays.Enabled = cfg.sunRaysEnabled
	end

	stopLightning()
	if cfg.lightning then
		task.delay(TWEEN_TIME, function()
			startLightning(cfg)
		end)
	end
end

function WeatherController:KnitInit() end

function WeatherController:KnitStart()
	local weatherService = Knit.GetService("WeatherService")
	weatherService.Weather:Observe(function(weatherType: string)
		applyWeather(weatherType)
	end)
end

return WeatherController