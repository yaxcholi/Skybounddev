local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)

local Interactable = Component.new({ Tag = "Interactable", Extensions = { TroveAdder, RemoteComponent } })

function Interactable:Construct()
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
end

function Interactable:Start()
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

function Interactable:SetNear(isNear: boolean)
	self._near:set(isNear)
end

function Interactable:SetCanInteract(canInteract: boolean)
	self._canInteract:set(canInteract)
end

function Interactable:IsNear(): boolean
	return Fusion.peek(self._near)
end

function Interactable:CanInteract(): boolean
	return Fusion.peek(self._canInteract)
end

function Interactable:GetDistance(position: Vector3): number
	return (position - self.Instance:GetPivot().Position).Magnitude
end

function Interactable:IsEnabled(): boolean
	return self.Instance:GetAttribute("Enabled") ~= false
end

function Interactable:SetTargetableFilter(filter: () -> boolean)
	self._targetableFilter = filter
end

function Interactable:IsTargetable(): boolean
	if not self:IsEnabled() then
		return false
	end

	if self._targetableFilter then
		return self._targetableFilter()
	end

	return true
end

function Interactable:GenerateUI()
	self._scope:New("SurfaceGui")({
		Name = "SurfaceGui",
		Brightness = 3,
		ClipsDescendants = true,
		Face = Enum.NormalId.Top,
		MaxDistance = 1000,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		Parent = self.Instance,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		[Fusion.Children] = {
			self._scope:New("Frame")({
				Name = "Frame",
				BackgroundTransparency = 1,
				Size = self._scope:Spring(
					self._scope:Computed(function(use)
						return use(self._near) and UDim2.fromScale(1, 1) or UDim2.fromScale(0, 0)
					end),
					15
				),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),

				[Fusion.Children] = {
					self._scope:New("UICorner")({
						Name = "UICorner",
						BottomLeftRadius = UDim.new(1, 0),
						BottomRightRadius = UDim.new(1, 0),
						CornerRadius = UDim.new(1, 0),
						TopLeftRadius = UDim.new(1, 0),
						TopRightRadius = UDim.new(1, 0),
					}),

					self._scope:New("UIStroke")({
						Name = "UIStroke",
						BorderStrokePosition = Enum.BorderStrokePosition.Inner,
						Color = Color3.new(1, 1, 1),
						Thickness = 10,
						Transparency = self._scope:Spring(
							self._scope:Computed(function(use)
								return use(self._near) and 0 or 1
							end),
							15
						),
					}),
				},
			}),
		},
	})

	if not self.Instance:GetAttribute("CustomPrompt") then
		self._scope:New("BillboardGui")({
			Name = "InteractPrompt",
			Size = UDim2.fromOffset(50, 50),
			StudsOffset = Vector3.new(0, 2, 0),
			AlwaysOnTop = true,
			Parent = self.Instance,

			[Fusion.Children] = {
				self._scope:New("TextLabel")({
					Name = "Prompt",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Font = Enum.Font.GothamBold,
					Text = "[E]",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextTransparency = self._scope:Spring(
						self._scope:Computed(function(use)
							return use(self._canInteract) and 0 or 1
						end),
						30
					),

					[Fusion.Children] = {
						self._scope:New("UIStroke")({
							Name = "UIStroke",
							Thickness = 2,
							Transparency = self._scope:Spring(
								self._scope:Computed(function(use)
									return use(self._canInteract) and 0 or 1
								end),
								30
							),
						}),
					},
				}),
			},
		})
	end
end

function Interactable:Stop() end

return Interactable
