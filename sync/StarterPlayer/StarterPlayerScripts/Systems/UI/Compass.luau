local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local CARDINAL_ROTATIONS: { [string]: number } = {
	N = -math.pi * 4 / 4,
	NE = -math.pi * 3 / 4,
	E = -math.pi * 2 / 4,
	SE = -math.pi * 1 / 4,
	S = math.pi * 0 / 4,
	SW = math.pi * 1 / 4,
	W = math.pi * 2 / 4,
	NW = math.pi * 3 / 4,
}

local function restrictAngle(angle: number): number
	if angle < -math.pi then
		return angle + math.pi * 2
	elseif angle > math.pi then
		return angle - math.pi * 2
	else
		return angle
	end
end

local Compass = Component.new({ Tag = "Compass", Extensions = { TroveAdder } })

function Compass:Construct()
	self._lastY = 0
	self._smoothness = self.Instance:GetAttribute("Smoothness") or 10
	self._units = {}

	for name, rotation in CARDINAL_ROTATIONS do
		local unit = self.Instance:FindFirstChild(name)
		if unit and unit:IsA("GuiObject") then
			self._units[unit] = rotation
		end
	end
end

function Compass:Start() end

function Compass:RenderSteppedUpdate(dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local look = camera.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.001 then
		return
	end
	flatLook = flatLook.Unit

	local lookY = math.atan2(flatLook.Z, flatLook.X)
	local difY = restrictAngle(lookY - self._lastY)
	lookY = restrictAngle(self._lastY + difY * dt * self._smoothness)
	self._lastY = lookY

	for unit, baseRotation in self._units do
		local rot = restrictAngle(lookY - baseRotation)
		if math.sin(rot) > 0 then
			local cosRot = math.cos(rot)
			unit.Visible = true
			unit.Position = UDim2.new(0.5 + cosRot * 0.6, unit.Position.X.Offset, 0, 3)
		else
			unit.Visible = false
		end
	end
end

function Compass:Stop() end

return Compass
