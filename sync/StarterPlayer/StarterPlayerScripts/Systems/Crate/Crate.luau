local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Input = require(ReplicatedStorage.Packages.Input)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Interactable = require(script.Parent.Parent.Interactions.Interactable)

local keyboard = Input.Keyboard.new()
local Crate = Component.new({ Tag = "Crate", Extensions = { TroveAdder, RemoteComponent } })

local function isHoldingAnyCrate(): boolean
	local localPlayer = Players.LocalPlayer

	for _, crate in Crate:GetAll() do
		if crate.Server.Holder:Get() == localPlayer then
			return true
		end
	end

	return false
end

local function isLocalHolder(crate): boolean
	return crate.Server.Holder:Get() == Players.LocalPlayer
end

function Crate:Construct()
	self._scope = Fusion.scoped({
		New = Fusion.New,
		Value = Fusion.Value,
		Spring = Fusion.Spring,
		Computed = Fusion.Computed,
		Children = Fusion.Children,
	})

	self._showPrompts = self._scope:Value(false)
	self._showOpen = self._scope:Value(false)
	self._showCarry = self._scope:Value(false)
	self._showDrop = self._scope:Value(false)
end

function Crate:HasAvailableInteractions(): boolean
	if isLocalHolder(self) then
		return true
	end

	return self.Instance:FindFirstChild("Door") ~= nil
end

function Crate:Start()
	local interaction = self.Instance:WaitForChild("Interaction")
	interaction:SetAttribute("CustomPrompt", true)

	Interactable:WaitForInstance(interaction):andThen(function(interactable)
		self._interactable = interactable
		interactable:SetTargetableFilter(function()
			return self:HasAvailableInteractions()
		end)
		self:GeneratePromptUI(interaction)
		self:StartPromptUpdates()
	end)

	self._trove:Add(keyboard.KeyDown:Connect(function(keyCode, gameProcessed)
		if gameProcessed or keyCode ~= Enum.KeyCode.Q then
			return
		end

		if isLocalHolder(self) then
			self.Server.Drop:Fire()
			return
		end

		if not Fusion.peek(self._showCarry) then
			return
		end

		self.Server.PickUp:Fire()
	end))
end

function Crate:GeneratePromptUI(interaction: Instance)
	local promptTransparency = self._scope:Spring(
		self._scope:Computed(function(use)
			return use(self._showPrompts) and 0 or 1
		end),
		30
	)

	local function promptLabel(name: string, layoutOrder: number, text: string, visible)
		return self._scope:New("TextLabel")({
			Name = name,
			LayoutOrder = layoutOrder,
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Size = UDim2.new(1, 0, 0, 22),
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			Visible = visible,
			TextTransparency = promptTransparency,

			[Fusion.Children] = {
				self._scope:New("UIStroke")({
					Name = "UIStroke",
					Thickness = 2,
					Transparency = promptTransparency,
				}),
			},
		})
	end

	self._scope:New("BillboardGui")({
		Name = "CrateInteractPrompt",
		Size = UDim2.fromOffset(180, 70),
		StudsOffset = Vector3.new(0, 2, 0),
		AlwaysOnTop = true,
		Parent = interaction,

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

					promptLabel(
						"OpenPrompt",
						1,
						"[E] Open Door",
						self._scope:Computed(function(use)
							return use(self._showOpen)
						end)
					),

					promptLabel(
						"CarryPrompt",
						2,
						"[Q] Carry",
						self._scope:Computed(function(use)
							return use(self._showCarry)
						end)
					),

					promptLabel(
						"DropPrompt",
						3,
						"[Q] Drop",
						self._scope:Computed(function(use)
							return use(self._showDrop)
						end)
					),
				},
			}),
		},
	})
end

function Crate:StartPromptUpdates()
	self._trove:Add(Timer.Simple(0.2, function()
		if not self._interactable then
			return
		end

		local isHeld = isLocalHolder(self)
		local canInteract = self._interactable:CanInteract()
		local isNear = self._interactable:IsNear()
		local hasDoor = self.Instance:FindFirstChild("Door") ~= nil

		self._showDrop:set(isHeld)
		self._showOpen:set(not isHeld and canInteract and hasDoor)
		self._showCarry:set(not isHeld and canInteract and hasDoor and not isHoldingAnyCrate())
		self._showPrompts:set(isHeld or (isNear and canInteract and self:HasAvailableInteractions()))
	end))
end

function Crate:Stop()
	Fusion.doCleanup(self._scope)
end

return Crate
