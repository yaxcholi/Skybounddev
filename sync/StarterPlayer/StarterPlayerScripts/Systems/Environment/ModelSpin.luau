local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local ModelSpin = Component.new({ Tag = "ModelSpin", Extensions = { TroveAdder } })

function ModelSpin:Construct()
	self._axis = self.Instance:GetAttribute("Axis") :: Vector3
	self._speed = self.Instance:GetAttribute("SpinSpeed") or 1

	if not self._axis then
		error("ModelSpin: Axis is required on " .. self.Instance:GetFullName())
	end
end

function ModelSpin:Start() end

function ModelSpin:Stop() end

function ModelSpin:RenderSteppedUpdate(dt: number)
	local currentPivot = self.Instance:GetPivot()
	local rotation = self._axis * self._speed * dt
	local newPivot = currentPivot * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
	self.Instance:PivotTo(newPivot)
end

return ModelSpin
