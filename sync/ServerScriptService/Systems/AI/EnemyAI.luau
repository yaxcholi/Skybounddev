local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Knit = require(ReplicatedStorage.Packages.Knit)

local EnemyAI = Component.new({ Tag = "EnemyAI", Extensions = { TroveAdder, RemoteComponent } })
local CHASE_DISTANCE = 200
local PLAYER_AGGRO_DISTANCE = 80
local GRAPPLE_DISTANCE = 130
local GRAPPLE_MIN_DISTANCE = 60
local STOP_DISTANCE = 8
local DEFAULT_ATTACK_DISTANCE = 8
local STEP_LOOKAHEAD = 5
local GROUND_CHECK_HEIGHT = 5
local GROUND_CHECK_DEPTH = 20
local GRAPPLE_COOLDOWN = 3
local GRAPPLE_START_DELAY = 1
local GRAPPLE_MIN_TIME = 0.7
local GRAPPLE_MAX_TIME = 1.6
local GRAPPLE_TIME_PER_STUD = 0.02
local randomGenerator = Random.new()

function EnemyAI:_getNearestPlayerTarget(maxDistance: number): (Vector3?, number)
	if not self._root then
		return nil, math.huge
	end

	local nearestPosition = nil
	local nearestDistance = maxDistance

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local characterRoot = character.PrimaryPart
		if not humanoid or humanoid.Health <= 0 or not characterRoot then
			continue
		end

		local offset = characterRoot.Position - self._root.Position
		local horizontalOffset = Vector3.new(offset.X, 0, offset.Z)
		local distance = horizontalOffset.Magnitude
		if distance < nearestDistance then
			nearestDistance = distance
			nearestPosition = characterRoot.Position
		end
	end

	return nearestPosition, nearestDistance
end

function EnemyAI:Construct()
	self._humanoid = self.Instance:FindFirstChildOfClass("Humanoid")
	self._root = self.Instance.PrimaryPart
	self._attackDistance = self.Instance:GetAttribute("AttackDistance") or DEFAULT_ATTACK_DISTANCE
	self._nextGrappleTime = 0
	self._isGrappling = false
	self._raycastParams = RaycastParams.new()
	self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self._raycastParams.IgnoreWater = false
	self._raycastParams.FilterDescendantsInstances = { self.Instance }

	self._trove:Add(self.Instance:GetAttributeChangedSignal("AttackDistance"):Connect(function()
		self._attackDistance = self.Instance:GetAttribute("AttackDistance") or DEFAULT_ATTACK_DISTANCE
	end))
end

function EnemyAI:_hasGroundAhead(moveDirection: Vector3): boolean
	local root = self._root
	if not root then
		return false
	end

	local projectedPosition = root.Position + (moveDirection * STEP_LOOKAHEAD)
	local rayOrigin = projectedPosition + Vector3.new(0, GROUND_CHECK_HEIGHT, 0)
	local rayDirection = Vector3.new(0, -GROUND_CHECK_DEPTH, 0)
	local result = workspace:Raycast(rayOrigin, rayDirection, self._raycastParams)

	return result ~= nil
end

function EnemyAI:_tryGrapple(targetAirship: Model, distance: number): boolean
	if
		distance > GRAPPLE_DISTANCE
		or distance < GRAPPLE_MIN_DISTANCE
		or os.clock() < self._nextGrappleTime
		or self._isGrappling
	then
		return false
	end

	local root = self._root
	local targetPart = targetAirship and targetAirship.PrimaryPart
	if not root or not targetPart then
		return false
	end

	local targetOffset = Vector3.new(
		randomGenerator:NextNumber(-targetPart.Size.X * 0.35, targetPart.Size.X * 0.35),
		randomGenerator:NextNumber(-targetPart.Size.Y * 0.2, targetPart.Size.Y * 0.2),
		randomGenerator:NextNumber(-targetPart.Size.Z * 0.35, targetPart.Size.Z * 0.35)
	)
	local targetWorldPosition = targetPart.CFrame:PointToWorldSpace(targetOffset) + Vector3.new(0, 15, 0)
	local toTarget = targetWorldPosition - root.Position
	if toTarget.Magnitude <= 0.001 then
		return false
	end

	local characterAttachment = Instance.new("Attachment")
	characterAttachment.Name = "EnemyGrappleCharacterAttachment"
	characterAttachment.Parent = root

	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "EnemyGrappleTargetAttachment"
	targetAttachment.Position = targetPart.CFrame:PointToObjectSpace(targetWorldPosition) + Vector3.new(0, 25, 0)
	targetAttachment.Parent = targetPart

	local rope = Instance.new("RopeConstraint")
	rope.Name = "EnemyGrappleRope"
	rope.Visible = true
	rope.Thickness = 0.12
	rope.Length = toTarget.Magnitude
	rope.Attachment0 = characterAttachment
	rope.Attachment1 = targetAttachment
	rope.Parent = root

	self._isGrappling = true
	self._humanoid:Move(Vector3.zero)
	self._nextGrappleTime = os.clock() + GRAPPLE_COOLDOWN

	local travelTime = math.clamp(distance * GRAPPLE_TIME_PER_STUD, GRAPPLE_MIN_TIME, GRAPPLE_MAX_TIME)
	local lookPosition = targetPart.Position
	local tween =
		TweenService:Create(root, TweenInfo.new(travelTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(targetWorldPosition, lookPosition) * CFrame.Angles(math.pi / 2, 0, 0),
		})

	local ropeUpdateConnection = RunService.Heartbeat:Connect(function()
		if rope.Parent and characterAttachment.Parent and targetAttachment.Parent then
			rope.Length = (characterAttachment.WorldPosition - targetAttachment.WorldPosition).Magnitude
		end
	end)

	local startedTween = false
	local function cleanup()
		if ropeUpdateConnection.Connected then
			ropeUpdateConnection:Disconnect()
		end
		if rope.Parent then
			rope:Destroy()
		end
		if characterAttachment.Parent then
			characterAttachment:Destroy()
		end
		if targetAttachment.Parent then
			targetAttachment:Destroy()
		end
		self._isGrappling = false
	end

	tween.Completed:Connect(cleanup)
	task.delay(GRAPPLE_START_DELAY, function()
		if not self._isGrappling then
			return
		end
		if not root.Parent or not targetPart.Parent or not rope.Parent then
			cleanup()
			return
		end
		startedTween = true
		tween:Play()
	end)

	task.delay(GRAPPLE_START_DELAY + travelTime + 0.25, function()
		if self._isGrappling and not startedTween then
			cleanup()
		end
	end)

	return true
end

function EnemyAI:Start()
	self._trove:Add(Timer.Simple(0.2, function()
		if self._boarded or not self._humanoid or not self._root then
			return
		end

		local primaryAirship = Knit.GetService("AirshipService"):GetPrimaryAirship()
		if not primaryAirship or not primaryAirship.PrimaryPart then
			self._humanoid:Move(Vector3.zero)
			return
		end

		local targetPosition = primaryAirship.PrimaryPart.Position
		local targetIsAirship = true
		local playerTargetPosition = self:_getNearestPlayerTarget(PLAYER_AGGRO_DISTANCE)
		if playerTargetPosition then
			targetPosition = playerTargetPosition
			targetIsAirship = false
		end

		local offset = targetPosition - self._root.Position
		local horizontalOffset = Vector3.new(offset.X, 0, offset.Z)
		local distance = horizontalOffset.Magnitude
		local attackDistance = self.Instance:GetAttribute("AttackDistance") or self._attackDistance
		local stopDistance = targetIsAirship and STOP_DISTANCE or attackDistance

		if distance > CHASE_DISTANCE or distance < stopDistance then
			self._humanoid:Move(Vector3.zero)
			return
		end

		if targetIsAirship and self:_tryGrapple(primaryAirship, distance) then
			return
		end

		local moveDirection = horizontalOffset.Unit
		if not self:_hasGroundAhead(moveDirection) then
			self._humanoid:Move(Vector3.zero)
			return
		end

		self._humanoid:Move(moveDirection)
	end))
end

function EnemyAI:Stop() end

return EnemyAI
