local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local AmmoTypeData = require(ReplicatedStorage.Data.AmmoType)
local WeaponsData = require(ReplicatedStorage.Data.Weapons)

local Collectable = Component.new({ Tag = "Collectable", Extensions = { TroveAdder, RemoteComponent } })

local function getItemData(instance)
	local itemName = instance:GetAttribute("ItemName")
	local itemType = instance:GetAttribute("Type")

	if not itemName then
		return {
			Name = "Unknown",
			Description = "",
		}
	end

	if itemType == "Weapon" then
		local weaponData = WeaponsData[itemName]
		if weaponData then
			return weaponData
		end
	elseif itemType == "AmmoType" then
		local ammoData = AmmoTypeData[itemName]
		if ammoData then
			return ammoData
		end
	end

	return WeaponsData[itemName] or AmmoTypeData[itemName] or {
		Name = itemName,
		Description = "",
	}
end

function Collectable:Construct()
	self._scope = Fusion.scoped({
		New = Fusion.New,
		Value = Fusion.Value,
		Spring = Fusion.Spring,
		Computed = Fusion.Computed,
		Children = Fusion.Children,
	})

	self._near = self._scope:Value(false)
	self._canInteract = self._scope:Value(false)
	self._range = self.Instance:GetAttribute("Range") or 15
	self._itemData = getItemData(self.Instance)
end

function Collectable:Start()
	self:GenerateUI()

	self._trove:Add(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if input.KeyCode ~= Enum.KeyCode.E then
			return
		end

		if not Fusion.peek(self._canInteract) then
			return
		end

		self.Server.OnInteract:Fire()
	end))
end

function Collectable:SetNear(isNear: boolean)
	self._near:set(isNear)
end

function Collectable:SetCanInteract(canInteract: boolean)
	self._canInteract:set(canInteract)
end

function Collectable:GetDistance(position: Vector3): number
	return (position - self.Instance:GetPivot().Position).Magnitude
end

function Collectable:GenerateUI()
	local promptTransparency = self._scope:Spring(
		self._scope:Computed(function(use)
			return use(self._canInteract) and 0 or 1
		end),
		30
	)

	self._scope:New("Highlight")({
		FillTransparency = 1,
		OutlineTransparency = self._scope:Spring(
			self._scope:Computed(function(use)
				return use(self._near) and 0 or 1
			end),
			15
		),
		Parent = self.Instance,
	})

	self._scope:New("BillboardGui")({
		Name = "InteractPrompt",
		Size = UDim2.fromOffset(220, 90),
		StudsOffset = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		Parent = self.Instance,

		[Fusion.Children] = {
			self._scope:New("Frame")({
				Name = "PromptFrame",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),

				[Fusion.Children] = {
					self._scope:New("UIListLayout")({
						Name = "UIListLayout",
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					self._scope:New("TextLabel")({
						Name = "ItemName",
						LayoutOrder = 1,
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						Size = UDim2.new(1, 0, 0, 24),
						Text = self._itemData.Name,
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						TextTransparency = promptTransparency,

						[Fusion.Children] = {
							self._scope:New("UIStroke")({
								Name = "UIStroke",
								Thickness = 2,
								Transparency = promptTransparency,
							}),
						},
					}),

					self._scope:New("TextLabel")({
						Name = "ItemDescription",
						LayoutOrder = 2,
						BackgroundTransparency = 1,
						Font = Enum.Font.Gotham,
						Size = UDim2.new(1, 0, 0, 18),
						Text = self._itemData.Description,
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextScaled = true,
						TextTransparency = promptTransparency,

						[Fusion.Children] = {
							self._scope:New("UIStroke")({
								Name = "UIStroke",
								Thickness = 1,
								Transparency = promptTransparency,
							}),
						},
					}),

					self._scope:New("TextLabel")({
						Name = "Prompt",
						LayoutOrder = 3,
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						Size = UDim2.new(1, 0, 0, 22),
						Text = "[E]",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						TextTransparency = promptTransparency,

						[Fusion.Children] = {
							self._scope:New("UIStroke")({
								Name = "UIStroke",
								Thickness = 2,
								Transparency = promptTransparency,
							}),
						},
					}),
				},
			}),
		},
	})
end

function Collectable:Stop() end

return Collectable
