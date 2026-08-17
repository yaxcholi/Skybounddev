local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local CAMERA_TWEEN_DURATION = 0.2

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Controls = require(Players.LocalPlayer.PlayerScripts.PlayerModule :: any):GetControls()
local Timer = require(ReplicatedStorage.Packages.Timer)

local Cannon = Component.new({ Tag = "Cannon", Extensions = { TroveAdder, RemoteComponent } })

function Cannon:Construct()
	self._controlling = false
	self._cameraTweening = false
	self._activeCameraTween = nil
	self._cachedCharacterCameraOffset = nil :: CFrame?
	self._startTime = 0
	self._targetAngles = Vector2.zero
end

local function getCannonCameraCFrame(instance: Instance): CFrame
	local attachment = instance:FindFirstChild("CameraAttachment", true) :: Attachment
	assert(attachment, "Cannon missing CameraAttachment")
	return attachment.WorldCFrame
end

local function cacheCharacterCameraOffset(character: Model): CFrame?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end

	return root.CFrame:ToObjectSpace(workspace.CurrentCamera.CFrame)
end

local function getCharacterCameraCFrame(character: Model, cachedOffset: CFrame?): CFrame
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not cachedOffset then
		return workspace.CurrentCamera.CFrame
	end

	return root.CFrame * cachedOffset
end

function Cannon:_cancelCameraTween()
	if self._activeCameraTween then
		self._activeCameraTween:Cancel()
		self._activeCameraTween = nil
	end
	self._cameraTweening = false
end

function Cannon:_tweenCameraTo(targetCFrame: CFrame, onComplete: (() -> ())?)
	self:_cancelCameraTween()

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	self._cameraTweening = true

	local tween = TweenService:Create(
		camera,
		TweenInfo.new(CAMERA_TWEEN_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ CFrame = targetCFrame }
	)
	self._activeCameraTween = tween
	tween:Play()

	tween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Cancelled then
			return
		end

		self._activeCameraTween = nil
		self._cameraTweening = false

		if onComplete then
			onComplete()
		end
	end)
end

function Cannon:Start()
	self._trove:Add(self.Server.Controller:Observe(function(player: Player?)
		local character = Players.LocalPlayer.Character

		if not character then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		local camera = workspace.CurrentCamera

		if player ~= Players.LocalPlayer then
			if self._controlling then
				self._controlling = false

				task.delay(0.1, function()
					humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
					humanoid.JumpHeight = StarterPlayer.CharacterJumpHeight
				end)

				self:_tweenCameraTo(getCharacterCameraCFrame(character, self._cachedCharacterCameraOffset), function()
					camera.CameraSubject = humanoid
					camera.CameraType = Enum.CameraType.Custom
					self._cachedCharacterCameraOffset = nil
				end)
			end
			return
		end

		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		self._controlling = true
		self._cachedCharacterCameraOffset = cacheCharacterCameraOffset(character)

		self:_tweenCameraTo(getCannonCameraCFrame(self.Instance))
	end))

	self._trove:Add(Timer.Simple(0.05, function()
		local moveVector = Controls:GetMoveVector()

		self._targetAngles += Vector2.new(moveVector.X, moveVector.Z)
		self.Server.UpdateTargetAngles:Fire(self._targetAngles)
	end))

	self._trove:Add(UserInputService.JumpRequest:Connect(function()
		self.Server.StopControl:Fire(Players.LocalPlayer)
	end))
end

function Cannon:RenderSteppedUpdate(_dt: number)
	if not self._controlling or self._cameraTweening then
		return
	end

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = getCannonCameraCFrame(self.Instance)
end

function Cannon:Stop()
	self:_cancelCameraTween()
end

return Cannon
