local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local FadeUI = Component.new({ Tag = "FadeUI", Extensions = { TroveAdder } })

function FadeUI:Construct()
	self._scope = Fusion.scoped({
		Value = Fusion.Value,
		Computed = Fusion.Computed,
		Hydrate = Fusion.Hydrate,
		Spring = Fusion.Spring,
	})

	self._transparency = self._scope:Value(1)
end

function FadeUI:Start()
	self._scope:Hydrate(self.Instance.Frame)({
		BackgroundTransparency = self._scope:Spring(self._transparency, 15),
	})
end

function FadeUI:FadeIn()
	self._transparency:set(0)
end

function FadeUI:FadeOut()
	self._transparency:set(1)
end

function FadeUI:Stop()
	Fusion.doCleanup(self._scope)
end

return FadeUI
