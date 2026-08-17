local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Input = require(ReplicatedStorage.Packages.Input)
local Knit = require(ReplicatedStorage.Packages.Knit)
local AmmoTypeData = require(ReplicatedStorage.Data.AmmoType)
local WeaponsData = require(ReplicatedStorage.Data.Weapons)
local WeaponUI = require(script.Parent.WeaponUI)

local RAY_DISTANCE = 500

local mouse = Input.Mouse.new()
local keyboard = Input.Keyboard.new()

local Weapon = Component.new({ Tag = "Weapon", Extensions = { TroveAdder, RemoteComponent } })

function Weapon:Construct()
	self._params = RaycastParams.new()
	self._params.FilterDescendantsInstances = { self.Instance }
	self._params.FilterType = Enum.RaycastFilterType.Exclude
	self._itemName = self.Instance:GetAttribute("ItemName") or self.Instance.Name
	self._weaponData = WeaponsData[self._itemName]
	self._ammoState = nil
end

function Weapon:SetWeaponUIVisible(isVisible: boolean)
	for _, weaponUI in WeaponUI:GetAll() do
		weaponUI:SetVisible(isVisible)
	end
end

function Weapon:IsLocalOwned(): boolean
	return self.Instance.Parent == Players.LocalPlayer.Character
end

function Weapon:GetAmmoTypeName(): string
	if self._ammoState and self._ammoState.AmmoTypeName then
		return self._ammoState.AmmoTypeName
	end

	if not self._weaponData then
		return ""
	end

	local ammoData = AmmoTypeData[self._weaponData.AmmoType]
	return (ammoData and ammoData.Name) or self._weaponData.AmmoType
end

function Weapon:UpdateWeaponUI()
	if not self._ammoState then
		return
	end

	for _, weaponUI in WeaponUI:GetAll() do
		weaponUI:SetWeaponName(self._ammoState.WeaponName or self._itemName)
		weaponUI:UpdateAmmoText(
			self._ammoState.Clip or 0,
			self._ammoState.ClipSize or 0,
			self._ammoState.AmmoTypeName or self:GetAmmoTypeName(),
			self._ammoState.Reserve or 0
		)
	end
end

function Weapon:_getHumanoid(): Humanoid?
	local parent = self.Instance.Parent
	if not parent or not parent:IsA("Model") then
		return nil
	end

	return parent:FindFirstChildOfClass("Humanoid")
end

function Weapon:_loadWeaponAnimations()
	self:_stopWeaponAnimations()

	local animsFolder = self.Instance:FindFirstChild("Anims")
	if not animsFolder then
		return
	end

	local humanoid = self:_getHumanoid()
	if not humanoid then
		return
	end

	local idleAnimation = animsFolder:FindFirstChild("Idle")
	if idleAnimation and idleAnimation:IsA("Animation") then
		self._idleTrack = humanoid:LoadAnimation(idleAnimation)
		self._idleTrack.Looped = true
		self._idleTrack.Priority = Enum.AnimationPriority.Idle
	end

	local firingAnimation = animsFolder:FindFirstChild("Firing")
	if firingAnimation and firingAnimation:IsA("Animation") then
		self._firingTrack = humanoid:LoadAnimation(firingAnimation)
		self._firingTrack.Looped = false
		self._firingTrack.Priority = Enum.AnimationPriority.Action
	end
end

function Weapon:_playIdle()
	if self._idleTrack then
		self._idleTrack:Play()
	end
end

function Weapon:_playFiring()
	if self._firingTrack then
		self._firingTrack:Play()
	end
end

function Weapon:_stopWeaponAnimations()
	if self._idleTrack then
		self._idleTrack:Stop()
		self._idleTrack = nil
	end

	if self._firingTrack then
		self._firingTrack:Stop()
		self._firingTrack = nil
	end
end

function Weapon:Start()
	local params = RaycastParams.new()

	self._trove:Add(self.Server.AmmoState:Observe(function(state)
		self._ammoState = state

		if not self:IsLocalOwned() or state == nil then
			self:SetWeaponUIVisible(false)
			return
		end

		self:SetWeaponUIVisible(true)
		self:UpdateWeaponUI()
	end))

	self._trove:Add(self.Instance.Equipped:Connect(function()
		if not self:IsLocalOwned() then
			return
		end

		self:SetWeaponUIVisible(true)
		self:_loadWeaponAnimations()
		self:_playIdle()
		if self._ammoState then
			self:UpdateWeaponUI()
		else
			for _, weaponUI in WeaponUI:GetAll() do
				weaponUI:SetWeaponName((self._weaponData and self._weaponData.Name) or self._itemName)
				weaponUI:UpdateAmmoText(
					0,
					(self._weaponData and self._weaponData.ClipSize) or 0,
					self:GetAmmoTypeName(),
					0
				)
			end
		end
	end))

	self._trove:Add(self.Instance.Unequipped:Connect(function()
		if not self:IsLocalOwned() then
			return
		end

		self:SetWeaponUIVisible(false)
		self:_stopWeaponAnimations()
	end))

	self._trove:Add(keyboard.KeyDown:Connect(function(keyCode)
		if keyCode ~= Enum.KeyCode.R then
			return
		end

		if self.Instance.Parent ~= Players.LocalPlayer.Character then
			return
		end

		self.Server.Reload:Fire()
	end))

	self._trove:Add(self.Instance.Activated:Connect(function()
		if not self:IsLocalOwned() then
			return
		end

		if self._ammoState and (self._ammoState.Clip or 0) <= 0 then
			return
		end

		local result = mouse:Raycast(params, RAY_DISTANCE)
		local worldPosition

		if result then
			worldPosition = result.Position
		else
			worldPosition = mouse:Project(RAY_DISTANCE)
		end

		self.Server.Shoot:Fire(worldPosition)
		self:_playFiring()

		local barrel = self.Instance:FindFirstChild("Barrel", true)
		if barrel then
			Knit.GetController("BulletRenderController"):RenderBullet(barrel.WorldPosition, worldPosition)
		end
	end))
end

function Weapon:Stop()
	self:SetWeaponUIVisible(false)
	self:_stopWeaponAnimations()
end

return Weapon
