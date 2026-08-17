local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local WeaponUI = Component.new({ Tag = "WeaponUI", Extensions = { TroveAdder } })

function WeaponUI:Construct()
	self._weaponNameLabel = self.Instance:WaitForChild("WeaponName")
	self._ammoLabel = self.Instance:WaitForChild("Ammo")
	self._reserveAmmoLabel = self.Instance:WaitForChild("ReserveAmmo")
end

function WeaponUI:Start()
	self:SetVisible(false)
end

function WeaponUI:SetVisible(isVisible: boolean)
	self.Instance.Enabled = isVisible
end

function WeaponUI:SetWeaponName(weaponName: string)
	if self._weaponNameLabel and self._weaponNameLabel:IsA("TextLabel") then
		self._weaponNameLabel.Text = weaponName
	end
end

function WeaponUI:UpdateAmmoText(currentClip: number, clipSize: number, ammoTypeName: string, reserveAmmo: number)
	if self._reserveAmmoLabel and self._reserveAmmoLabel:IsA("TextLabel") then
		self._reserveAmmoLabel.Text = `{ammoTypeName}: {reserveAmmo}`
	end

	if self._ammoLabel and self._ammoLabel:IsA("TextLabel") then
		if self._reserveAmmoLabel then
			self._ammoLabel.Text = `{currentClip}/{clipSize}`
		else
			self._ammoLabel.Text = `{currentClip}/{clipSize} | {ammoTypeName}: {reserveAmmo}`
		end
	end
end

function WeaponUI:Stop() end

return WeaponUI
