local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Timer = require(ReplicatedStorage.Packages.Timer)

local MeleeEnemy = Component.new({ Tag = "MeleeEnemy", Extensions = { TroveAdder, RemoteComponent } })
local DEFAULT_DAMAGE = 15
local DEFAULT_RADIUS = 8
local DEFAULT_TICK = 0.2
local DEFAULT_TARGET_COOLDOWN = 0.75
local ATTACK_DISTANCE_ATTRIBUTE = "AttackDistance"

function MeleeEnemy:Construct()
	self._root = self.Instance.PrimaryPart
	self._damage = self.Instance:GetAttribute("Damage") or DEFAULT_DAMAGE
	self._radius = self.Instance:GetAttribute("DamageRadius") or DEFAULT_RADIUS
	self._tickRate = self.Instance:GetAttribute("DamageTickRate") or DEFAULT_TICK
	self._targetCooldown = self.Instance:GetAttribute("DamageCooldown") or DEFAULT_TARGET_COOLDOWN
	self._nextDamageByHumanoid = {}

	if self.Instance:GetAttribute(ATTACK_DISTANCE_ATTRIBUTE) == nil then
		self.Instance:SetAttribute(ATTACK_DISTANCE_ATTRIBUTE, self._radius)
	end
end

function MeleeEnemy:_damageNearbyPlayers()
	local root = self._root
	if not root then
		return
	end

	local now = os.clock()
	local radius = self._radius
	local radiusSquared = radius * radius

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
		if horizontalOffset:Dot(horizontalOffset) > radiusSquared then
			continue
		end

		local nextAllowedDamageTime = self._nextDamageByHumanoid[humanoid] or 0
		if now < nextAllowedDamageTime then
			continue
		end

		humanoid:TakeDamage(self._damage)
		self._nextDamageByHumanoid[humanoid] = now + self._targetCooldown
	end
end

function MeleeEnemy:Start()
	self._trove:Add(Timer.Simple(self._tickRate, function()
		self:_damageNearbyPlayers()
	end))
end

function MeleeEnemy:Stop()
	table.clear(self._nextDamageByHumanoid)
end

return MeleeEnemy