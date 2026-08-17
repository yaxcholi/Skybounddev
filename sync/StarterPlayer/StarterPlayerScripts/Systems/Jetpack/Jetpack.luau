local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Input = require(ReplicatedStorage.Packages.Input)
local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Controls = require(Players.LocalPlayer.PlayerScripts.PlayerModule :: any):GetControls()
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)

local JETPACK_SPEED = 40
local SMOOTHING = 1.5

local keyboard = Input.Keyboard.new()

local Jetpack = Component.new({ Tag = "Jetpack", Extensions = { TroveAdder, RemoteComponent } })

function Jetpack:Construct()
	self._touchTrove = self._trove:Extend()
	self._active = false
end

function Jetpack:Start()
	self:CreateConstraints()
	self:SetupMobileUI()
	self:SetupKeyboardInput()
	self:SetupHumanoidConnections()
end

function Jetpack:CreateConstraints()
	local linearVelocity = self._trove:Add(Instance.new("LinearVelocity")) :: LinearVelocity
	local alignOrientation = self._trove:Add(Instance.new("AlignOrientation")) :: AlignOrientation

	local humanoidRootPart = self.Instance.Parent:WaitForChild("HumanoidRootPart")
	local rootRigAttachment = humanoidRootPart:WaitForChild("RootRigAttachment")

	linearVelocity.Attachment0 = rootRigAttachment
	alignOrientation.Attachment0 = rootRigAttachment
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.RigidityEnabled = true

	linearVelocity.MaxForce = 1000000

	linearVelocity.Enabled = false
	alignOrientation.Enabled = false

	linearVelocity.Parent = humanoidRootPart
	alignOrientation.Parent = humanoidRootPart

	self._linearVelocity = linearVelocity
	self._alignOrientation = alignOrientation
end

function Jetpack:SetupMobileUI()
	local touchGuiStreamable = Streamable.new(Players.LocalPlayer.PlayerGui, "TouchGui")

	self._trove:Add(touchGuiStreamable:Observe(function(screenGui, trove)
		local jumpButton = screenGui:FindFirstChild("JumpButton", true)

		self._touchTrove:Add(jumpButton.MouseButton1Down:Connect(function()
			self:StartFlying()
		end))

		self._touchTrove:Add(jumpButton.MouseButton1Up:Connect(function()
			self:StopFlying()
		end))

		trove:Add(function()
			self._touchTrove:Clean()
		end)
	end))
end

function Jetpack:SetupKeyboardInput()
	self._trove:Add(keyboard.KeyDown:Connect(function(keyCode)
		if keyCode == Enum.KeyCode.Space or keyCode == Enum.KeyCode.ButtonA then
			self:StartFlying()
		end
	end))

	self._trove:Add(keyboard.KeyUp:Connect(function(keyCode)
		if keyCode == Enum.KeyCode.Space or keyCode == Enum.KeyCode.ButtonA then
			self:StopFlying()
		end
	end))
end

function Jetpack:SetupHumanoidConnections()
	local humanoid = self.Instance.Parent:WaitForChild("Humanoid") :: Humanoid
	self._trove:Add(humanoid.Died:Connect(function()
		self:StopFlying()
	end))
end

function Jetpack:StartFlying()
	local handle = self.Instance:WaitForChild("Handle")
	self._linearVelocity.VectorVelocity = handle.AssemblyLinearVelocity

	self._linearVelocity.Enabled = true
	self._alignOrientation.Enabled = true

	self._active = true

	self.Server:Enable()
end

function Jetpack:StopFlying()
	self._active = false

	self._linearVelocity.Enabled = false
	self._alignOrientation.Enabled = false

	self._linearVelocity.VectorVelocity = Vector3.zero

	self.Server:Disable()
end

function Jetpack:SteppedUpdate(dt: number)
	if not self._active then
		return
	end

	local moveVector = Controls:GetMoveVector()

	local camera = workspace.CurrentCamera
	local goalVelocity = Vector3.zero
	if moveVector.Magnitude == 0 then
		goalVelocity = Vector3.new(0, 1, 0) * JETPACK_SPEED
	else
		local forward = (camera.CFrame.LookVector + Vector3.new(0, 0.3, 0)).Unit
		local right = camera.CFrame.RightVector

		local velocity = -forward * moveVector.Z + right * moveVector.X
		goalVelocity = velocity * JETPACK_SPEED
	end

	self._linearVelocity.VectorVelocity = self._linearVelocity.VectorVelocity:Lerp(goalVelocity, dt * SMOOTHING)
	self._alignOrientation.CFrame = camera.CFrame
end

function Jetpack:Stop() end

return Jetpack
