local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Knit = require(ReplicatedStorage.Packages.Knit)
local AmmoTypeData = require(ReplicatedStorage.Data.AmmoType)
local WeaponsData = require(ReplicatedStorage.Data.Weapons)

local RAY_DISTANCE = 500
local CURRENT_CLIP_ATTRIBUTE = "CurrentClip"
local AMMO_AMOUNT_ATTRIBUTE = "AmmoAmount"

local Weapon = Component.new({ Tag = "Weapon", Extensions = { TroveAdder, RemoteComponent } })
Weapon.Client = {
	Shoot = Knit.CreateSignal(),
	Reload = Knit.CreateSignal(),
	AmmoState = Knit.CreateProperty(nil),
}

function Weapon:Construct()
	self._params = RaycastParams.new()
	self._params.FilterDescendantsInstances = { self.Instance }
	self._params.FilterType = Enum.RaycastFilterType.Exclude
	self._itemName = self.Instance:GetAttribute("ItemName") or self.Instance.Name
	self._weaponData = WeaponsData[self._itemName]
	if not self._weaponData then
		error(`Weapon data missing for {self._itemName}`)
	end
end

function Weapon:GetOwner(): Player?
	local character = self.Instance.Parent
	if not character or not character:IsA("Model") then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

function Weapon:GetClipSize(): number
	return self._weaponData.ClipSize or 0
end

function Weapon:GetCurrentClip(): number
	local currentClip = self.Instance:GetAttribute(CURRENT_CLIP_ATTRIBUTE)
	if currentClip == nil then
		return 0
	end

	return currentClip
end

function Weapon:SetCurrentClip(value: number)
	self.Instance:SetAttribute(CURRENT_CLIP_ATTRIBUTE, math.max(value, 0))
end

function Weapon:CountReserveAmmo(player: Player): number
	local ammoType = self._weaponData.AmmoType
	local total = 0

	local function accumulateFrom(container: Instance?)
		if not container then
			return
		end

		for _, item in container:GetChildren() do
			if not item:IsA("Tool") then
				continue
			end

			if item:GetAttribute("Type") ~= "AmmoType" or item:GetAttribute("ItemName") ~= ammoType then
				continue
			end

			local ammoAmount = item:GetAttribute(AMMO_AMOUNT_ATTRIBUTE) or 0
			total += ammoAmount
		end
	end

	accumulateFrom(player.Character)
	accumulateFrom(player.Backpack)

	return total
end

function Weapon:ConsumeReserveAmmo(player: Player, amount: number): number
	local ammoType = self._weaponData.AmmoType
	local remaining = amount
	local consumed = 0

	local function consumeFrom(container: Instance?)
		if not container then
			return
		end

		for _, item in container:GetChildren() do
			if remaining <= 0 then
				break
			end

			if not item:IsA("Tool") then
				continue
			end

			if item:GetAttribute("Type") ~= "AmmoType" or item:GetAttribute("ItemName") ~= ammoType then
				continue
			end

			local ammoAmount = item:GetAttribute(AMMO_AMOUNT_ATTRIBUTE) or 0
			if ammoAmount <= 0 then
				continue
			end

			local taken = math.min(ammoAmount, remaining)
			local updatedAmount = ammoAmount - taken
			item:SetAttribute(AMMO_AMOUNT_ATTRIBUTE, updatedAmount)
			consumed += taken
			remaining -= taken

			if updatedAmount <= 0 then
				item:Destroy()
			end
		end
	end

	consumeFrom(player.Character)
	consumeFrom(player.Backpack)

	return consumed
end

function Weapon:UpdateAmmoStateFor(player: Player?)
	if not player then
		self.Client.AmmoState:Set(nil)
		return
	end

	self.Client.AmmoState:Set({
		WeaponName = self._weaponData.Name or self._itemName,
		AmmoTypeName = (AmmoTypeData[self._weaponData.AmmoType] and AmmoTypeData[self._weaponData.AmmoType].Name)
			or self._weaponData.AmmoType,
		Clip = self:GetCurrentClip(),
		ClipSize = self:GetClipSize(),
		Reserve = self:CountReserveAmmo(player),
	})
end

function Weapon:Reload(player: Player)
	if self:GetOwner() ~= player then
		return
	end

	local clipSize = self:GetClipSize()
	local currentClip = self:GetCurrentClip()
	local missing = math.max(clipSize - currentClip, 0)
	if missing <= 0 then
		self:UpdateAmmoStateFor(player)
		return
	end

	local consumed = self:ConsumeReserveAmmo(player, missing)
	if consumed <= 0 then
		self:UpdateAmmoStateFor(player)
		return
	end

	self:SetCurrentClip(currentClip + consumed)
	self:UpdateAmmoStateFor(player)
end

function Weapon:Start()
	self._trove:Add(self.Instance.Equipped:Connect(function()
		local owner = self:GetOwner()
		if not owner then
			return
		end

		if self.Instance:GetAttribute(CURRENT_CLIP_ATTRIBUTE) == nil then
			self:SetCurrentClip(0)
		end

		self:UpdateAmmoStateFor(owner)
	end))

	self._trove:Add(self.Instance.Unequipped:Connect(function()
		self.Client.AmmoState:Set(nil)
	end))

	self._trove:Add(self.Client.Shoot:Connect(function(player: Player, worldPosition: Vector3)
		local character = player.Character
		if not character then
			return
		end

		if character ~= self.Instance.Parent then
			return
		end

		local currentClip = self:GetCurrentClip()
		if currentClip <= 0 then
			self:UpdateAmmoStateFor(player)
			return
		end

		self:SetCurrentClip(currentClip - 1)

		local barrel = self.Instance:FindFirstChild("Barrel", true)
		if not barrel then
			self:UpdateAmmoStateFor(player)
			return
		end

		local origin = barrel.WorldPosition

		local direction = (worldPosition - origin).Unit
		local result = workspace:Raycast(origin, direction * RAY_DISTANCE, self._params)
		local hitPosition = origin + direction * RAY_DISTANCE

		if result and result.Instance then
			local humanoid = result.Instance.Parent:FindFirstChild("Humanoid")

			if humanoid then
				humanoid:TakeDamage(self._weaponData.Damage or 50)
			end

			hitPosition = result.Position
		end

		Knit.GetService("WeaponService"):FireBullet(player, origin, hitPosition)
		self:UpdateAmmoStateFor(player)
	end))

	self._trove:Add(self.Client.Reload:Connect(function(player: Player)
		self:Reload(player)
	end))
end

function Weapon:Stop() end

return Weapon
