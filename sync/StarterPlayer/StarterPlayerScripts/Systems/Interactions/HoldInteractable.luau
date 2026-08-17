local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local ReviveUtil = require(ReplicatedStorage.Utils.ReviveUtil)

local HoldInteractable = Component.new({ Tag = "HoldInteractable", Extensions = { TroveAdder, RemoteComponent } })

function HoldInteractable:Construct()
	self._scope = Fusion.scoped({
		New = Fusion.New,
		Value = Fusion.Value,
		Spring = Fusion.Spring,
		Computed = Fusion.Computed,
		Children = Fusion.Children,
	})

	self._near = self._scope:Value(false)
	self._canInteract = self._scope:Value(false)
	self._isHolding = self._scope:Value(false)
	self._holdProgress = self._scope:Value(0)
	self._range = self.Instance:GetAttribute("Range") or 10
	self._holdDuration = self.Instance:GetAttribute("HoldDuration") or 3
	self._promptText = self.Instance:GetAttribute("InteractionPrompt") or "Interact"
	self._holdElapsed = 0
end

function HoldInteractable:IsHolding(): boolean
	return Fusion.peek(self._isHolding)
end

function HoldInteractable:_hasRequiredTool(): boolean
	local requiredTool = self.Instance:GetAttribute("RequiredTool")
	if not requiredTool then
		return true
	end

	local character = Players.LocalPlayer.Character
	if not character then
		return false
	end

	return ReviveUtil.hasRequiredToolEquipped(character, requiredTool)
end

function HoldInteractable:_canContinueHold(): boolean
	if not self:IsTargetable() then
		return false
	end

	local character = Players.LocalPlayer.Character
	if not character then
		return false
	end

	if not self:_hasRequiredTool() then
		return false
	end

	return self:GetDistance(character:GetPivot().Position) <= self._range
end

function HoldInteractable:_resetHold()
	self._isHolding:set(false)
	self._holdElapsed = 0
	self._holdProgress:set(0)
end

function HoldInteractable:Start()
	self:GenerateUI()

	self._trove:Add(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.E then
			return
		end

		if not Fusion.peek(self._canInteract) then
			return
		end

		self._isHolding:set(true)
		self._holdElapsed = 0
		self._holdProgress:set(0)
	end))

	self._trove:Add(UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.E then
			return
		end

		if Fusion.peek(self._isHolding) then
			self:_resetHold()
		end
	end))

	self._trove:Add(RunService.Heartbeat:Connect(function(dt)
		if not Fusion.peek(self._isHolding) then
			return
		end

		if not self:_canContinueHold() then
			self:_resetHold()
			return
		end

		self._holdElapsed += dt
		local progress = math.clamp(self._holdElapsed / self._holdDuration, 0, 1)
		self._holdProgress:set(progress)

		if progress >= 1 then
			self:_resetHold()
			self.Server.OnHoldComplete:Fire()
		end
	end))
end

function HoldInteractable:SetNear(isNear: boolean)
	self._near:set(isNear)
end

function HoldInteractable:SetCanInteract(canInteract: boolean)
	self._canInteract:set(canInteract)

	if not canInteract and not self:IsHolding() then
		self:_resetHold()
	end
end

function HoldInteractable:GetDistance(position: Vector3): number
	return (position - self.Instance:GetPivot().Position).Magnitude
end

function HoldInteractable:IsEnabled(): boolean
	return self.Instance:GetAttribute("Enabled") ~= false
end

function HoldInteractable:IsTargetable(): boolean
	if not self:IsEnabled() then
		return false
	end

	local character = Players.LocalPlayer.Character
	if not character then
		return false
	end

	if character:HasTag("Dead") or character:HasTag("Downed") then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if not self:_hasRequiredTool() then
		return false
	end

	return true
end

function HoldInteractable:GenerateUI()
	local promptTransparency = self._scope:Spring(
		self._scope:Computed(function(use)
			return use(self._canInteract) and 0 or 1
		end),
		30
	)

	local showProgress = self._scope:Computed(function(use)
		return use(self._isHolding)
	end)

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
		Name = "HoldInteractPrompt",
		Size = UDim2.fromOffset(220, 96),
		StudsOffset = Vector3.new(0, 3.5, 0),
		AlwaysOnTop = true,
		MaxDistance = 100,
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
						Padding = UDim.new(0, 4),
					}),

					self._scope:New("TextLabel")({
						Name = "Prompt",
						LayoutOrder = 1,
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						Size = UDim2.new(1, 0, 0, 22),
						Text = self._scope:Computed(function()
							return `[Hold E] {self._promptText}`
						end),
						TextColor3 = Color3.fromRGB(140, 255, 140),
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

					self._scope:New("Frame")({
						Name = "ProgressBar",
						LayoutOrder = 2,
						BackgroundColor3 = Color3.fromRGB(40, 40, 40),
						BackgroundTransparency = 0.2,
						Size = UDim2.new(1, 0, 0, 8),
						Visible = showProgress,

						[Fusion.Children] = {
							self._scope:New("UICorner")({
								Name = "UICorner",
								CornerRadius = UDim.new(0, 4),
							}),

							self._scope:New("Frame")({
								Name = "Fill",
								BackgroundColor3 = Color3.fromRGB(90, 220, 90),
								BorderSizePixel = 0,
								Size = self._scope:Computed(function(use)
									return UDim2.fromScale(use(self._holdProgress), 1)
								end),

								[Fusion.Children] = {
									self._scope:New("UICorner")({
										Name = "UICorner",
										CornerRadius = UDim.new(0, 4),
									}),
								},
							}),
						},
					}),
				},
			}),
		},
	})
end

function HoldInteractable:Stop()
	Fusion.doCleanup(self._scope)
end

return HoldInteractable
