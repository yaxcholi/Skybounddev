local WeatherConfig = {}

WeatherConfig.Types = {
	None = {
		colorCorrection = { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) },
		atmosphere = { Density = 0.395, Offset = 0, Color = Color3.fromRGB(199, 199, 199), Decay = Color3.fromRGB(106, 127, 139), Glare = 0, Haze = 0 },
		sunRaysEnabled = true,
		lightning = false,
	},
	Lightning = {
		colorCorrection = { Brightness = -0.25, Contrast = 0.1, Saturation = -0.5, TintColor = Color3.fromRGB(175, 190, 215) },
		atmosphere = { Density = 0.75, Offset = 0.05, Color = Color3.fromRGB(95, 105, 125), Decay = Color3.fromRGB(55, 65, 85), Glare = 0, Haze = 2.5 },
		sunRaysEnabled = false,
		lightning = true,
		lightningInterval = { min = 5, max = 15 },
		lightningFlashBrightness = 1.2,
		lightningFlashDuration = 0.08,
	},
}

return WeatherConfig