local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Knit = require(ReplicatedStorage.Packages.Knit)

local RangedEnemy = Component.new({ Tag = "RangedEnemy", Extensions = { TroveAdder, RemoteComponent } })
local DEFAULT_ATTACK_DISTANCE = 45
local ATTACK_DISTANCE_ATTRIBUTE = "AttackDistance"
local DEFAULT_SHOT_DAMAGE = 10
local DEFAULT_FIRE_RATE = 1

function RangedEnemy:Construct()
	self._root = self.Instance.PrimaryPart
	self._shotDamage = self.Instance:GetAttribute("ShotDamage") or DEFAULT_SHOT_DAMAGE
	self._fireRate = self.Instance:GetAttribute("FireRate") or DEFAULT_FIRE_RATE
	local barrelCandidate = self.Instance:FindFirstChild("Barrel", true)
	if barrelCandidate and barrelCandidate:IsA("Attachment") then
		self._barrelAttachment = barrelCandidate
	else
		self._barrelAttachment = nil
	end

	if not self._barrelAttachment and self._root then
		local barrelAttachment = Instance.new("Attachment")
		barrelAttachment.Name = "EnemyBarrel"
		barrelAttachment.Parent = self._root
		self._barrelAttachment = barrelAttachment
		self._trove:Add(barrelAttachment)
	end

	if self.Instance:GetAttribute(ATTACK_DISTANCE_ATTRIBUTE) == nil then
		self.Instance:SetAttribute(ATTACK_DISTANCE_ATTRIBUTE, DEFAULT_ATTACK_DISTANCE)
	end
end

function RangedEnemy:_getNearestPlayerInRange(range: number): (Humanoid?, BasePart?)
	local root = self._root
	if not root then
		return nil
	end

	local nearestHumanoid = nil
	local nearestRoot = nil
	local nearestDistanceSquared = range * range

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

		local offset = characterRoot.Position - root.Position
		local horizontalOffset = Vector3.new(offset.X, 0, offset.Z)
		local distanceSquared = horizontalOffset:Dot(horizontalOffset)
		if distanceSquared < nearestDistanceSquared then
			nearestDistanceSquared = distanceSquared
			nearestHumanoid = humanoid
			nearestRoot = characterRoot
		end
	end

	return nearestHumanoid, nearestRoot
end

function RangedEnemy:_faceTarget(targetRoot: BasePart)
	local root = self._root
	if not root then
		return
	end

	local targetPosition = targetRoot.Position
	local lookTarget = Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z)
	local lookOffset = lookTarget - root.Position
	if lookOffset.Magnitude <= 0.001 then
		return
	end

	root.CFrame = CFrame.lookAt(root.Position, lookTarget)
end

function RangedEnemy:Start()
	self._trove:Add(Timer.Simple(self._fireRate, function()
		local attackDistance = self.Instance:GetAttribute(ATTACK_DISTANCE_ATTRIBUTE) or DEFAULT_ATTACK_DISTANCE
		local targetHumanoid, targetRoot = self:_getNearestPlayerInRange(attackDistance)
		if not targetHumanoid or not targetRoot then
			return
		end

		self:_faceTarget(targetRoot)
		targetHumanoid:TakeDamage(self._shotDamage)

		if self._barrelAttachment then
			Knit.GetService("WeaponService"):FireBullet(nil, self._barrelAttachment.WorldPosition, targetRoot.Position)
		end
	end))
end

function RangedEnemy:Stop()
end

return RangedEnemy