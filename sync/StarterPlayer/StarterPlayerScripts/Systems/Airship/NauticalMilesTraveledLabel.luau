local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Knit = require(ReplicatedStorage.Packages.Knit)

local function formatWithCommas(value: number): string
	local formatted = string.format("%.1f", value)
	local integerPart, decimalPart = formatted:match("^(-?%d+)(%.%d+)$")
	if not integerPart then
		return formatted
	end

	repeat
		local newIntegerPart, count = string.gsub(integerPart, "^(-?%d+)(%d%d%d)", "%1,%2")
		integerPart = newIntegerPart
	until count == 0

	return integerPart .. decimalPart
end

local NauticalMilesTraveledLabel = Component.new({ Tag = "NauticalMilesTraveledLabel", Extensions = { TroveAdder } })

function NauticalMilesTraveledLabel:Construct()
	assert(self.Instance:IsA("TextLabel"), "NauticalMilesTraveledLabel must be placed on a TextLabel")
end

function NauticalMilesTraveledLabel:Start()
	self._trove:Add(Knit.GetService("AirshipService").TotalDistanceTraveled:Observe(function(distance: number)
		self.Instance.Text = `{formatWithCommas(distance)} NAUTICAL MILES TRAVELED`
	end))
end

function NauticalMilesTraveledLabel:Stop() end

return NauticalMilesTraveledLabel
