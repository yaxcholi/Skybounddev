local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Knit = require(ReplicatedStorage.Packages.Knit)

local EnemyTurret = Component.new({ Tag = "EnemyTurret", Extensions = { TroveAdder } })

local SPIN_UP_TIME = 1
local FIRE_RATE = 1
local DEFAULT_MOTOR_SPEED = 50
local DEFAULT_SHOT_DAMAGE = 10
local DEFAULT_ATTACK_DISTANCE = 150
local ATTACK_DISTANCE_ATTRIBUTE = "AttackDistance"

function EnemyTurret:Construct()
	self._primaryPart = self.Instance.PrimaryPart
	self._yawServo = self.Instance:FindFirstChild("YawServo", true) :: HingeConstraint?
	self._pitchServo = self.Instance:FindFirstChild("PitchServo", true) :: HingeConstraint?
	self._gunMotor = self.Instance:FindFirstChild("GunMotor", true) :: HingeConstraint?
	self._motorSpeed = self.Instance:GetAttribute("MotorSpeed") or DEFAULT_MOTOR_SPEED
	self._shotDamage = self.Instance:GetAttribute("ShotDamage") or DEFAULT_SHOT_DAMAGE
	self._attackDistance = self.Instance:GetAttribute(ATTACK_DISTANCE_ATTRIBUTE) or DEFAULT_ATTACK_DISTANCE

	self._raycastParams = RaycastParams.new()
	self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self._raycastParams.FilterDescendantsInstances = { self.Instance }

	self._trove:Add(self.Instance:GetAttributeChangedSignal(ATTACK_DISTANCE_ATTRIBUTE):Connect(function()
		self._attackDistance = self.Instance:GetAttribute(ATTACK_DISTANCE_ATTRIBUTE) or DEFAULT_ATTACK_DISTANCE
	end))

	local barrelCandidate = self.Instance:FindFirstChild("Barrel", true)
	if barrelCandidate and barrelCandidate:IsA("Attachment") then
		self._barrelAttachment = barrelCandidate
	elseif self._primaryPart then
		local barrelAttachment = Instance.new("Attachment")
		barrelAttachment.Name = "Barrel"
		barrelAttachment.Parent = self._primaryPart
		self._barrelAttachment = barrelAttachment
		self._trove:Add(barrelAttachment)
	else
		self._barrelAttachment = nil
	end

	self._timeOnTarget = 0
	self._timeSinceLastShot = FIRE_RATE

	if self.Instance:GetAttribute(ATTACK_DISTANCE_ATTRIBUTE) == nil then
		self.Instance:SetAttribute(ATTACK_DISTANCE_ATTRIBUTE, DEFAULT_ATTACK_DISTANCE)
	end
end

function EnemyTurret:_getAimOrigin(): Vector3
	if self._barrelAttachment then
		return self._barrelAttachment.WorldPosition
	end

	return self._primaryPart.Position
end

function EnemyTurret:_hasLineOfSight(targetRoot: BasePart): boolean
	local origin = self:_getAimOrigin()
	local direction = targetRoot.Position - origin
	local distance = direction.Magnitude
	if distance <= 1e-4 then
		return true
	end

	local result = workspace:Raycast(origin, direction, self._raycastParams)
	if not result then
		return true
	end

	local character = targetRoot.Parent
	if not character then
		return false
	end

	return result.Instance:IsDescendantOf(character)
end

function EnemyTurret:_setMotorSpinning(spinning: boolean)
	if not self._gunMotor then
		return
	end

	self._gunMotor.AngularVelocity = if spinning then self._motorSpeed else 0
end

function EnemyTurret:_getNearestPlayerRoot(): BasePart?
	if not self._primaryPart then
		return nil
	end

	local origin = self:_getAimOrigin()
	local rangeSquared = self._attackDistance * self._attackDistance
	local nearestRoot = nil
	local nearestDistanceSquared = math.huge

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local characterRoot = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoid or humanoid.Health <= 0 or not characterRoot then
			continue
		end

		local offset = characterRoot.Position - origin
		local distanceSquared = offset:Dot(offset)
		if distanceSquared > rangeSquared or distanceSquared >= nearestDistanceSquared then
			continue
		end

		if not self:_hasLineOfSight(characterRoot) then
			continue
		end

		nearestDistanceSquared = distanceSquared
		nearestRoot = characterRoot
	end

	return nearestRoot
end

function EnemyTurret:_aimAt(targetRoot: BasePart)
	if not self._primaryPart or not self._yawServo or not self._pitchServo then
		return
	end

	local sourcePos = self._primaryPart.Position
	local targetPos = targetRoot.Position
	local lookCFrame = CFrame.lookAt(sourcePos, targetPos)
	local relativeLook = self._primaryPart.CFrame:ToObjectSpace(lookCFrame)

	local pitch, yaw, _ = relativeLook:ToEulerAnglesYXZ()
	self._yawServo.TargetAngle = math.deg(yaw)
	self._pitchServo.TargetAngle = math.deg(-pitch)
end

function EnemyTurret:_fire(targetRoot: BasePart)
	local character = targetRoot.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(self._shotDamage)
	end

	if self._barrelAttachment then
		Knit.GetService("WeaponService"):FireBullet(nil, self._barrelAttachment.WorldPosition, targetRoot.Position)
	end
end

function EnemyTurret:SteppedUpdate(dt: number)
	if not self._primaryPart or not self._yawServo or not self._pitchServo then
		return
	end

	local targetRoot = self:_getNearestPlayerRoot()
	if not targetRoot then
		self._timeOnTarget = 0
		self._timeSinceLastShot = FIRE_RATE
		self:_setMotorSpinning(false)
		return
	end

	self:_aimAt(targetRoot)
	self:_setMotorSpinning(true)
	self._timeOnTarget += dt

	if self._timeOnTarget < SPIN_UP_TIME then
		return
	end

	self._timeSinceLastShot += dt
	if self._timeSinceLastShot < FIRE_RATE then
		return
	end

	self._timeSinceLastShot = 0
	self:_fire(targetRoot)
end

function EnemyTurret:Stop() end

return EnemyTurret
