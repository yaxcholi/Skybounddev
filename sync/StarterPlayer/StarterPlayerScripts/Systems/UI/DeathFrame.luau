local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Knit = require(ReplicatedStorage.Packages.Knit)

local SHOW_SPRING_SPEED = 22
local SHOW_SPRING_DAMPING = 0.85
local SLIDE_OFFSET = 36

local DeathFrame = Component.new({ Tag = "DeathFrame", Extensions = { TroveAdder } })

local function offsetPosition(rest: UDim2, alpha: number, offset: number, fromTop: boolean?): UDim2
	local direction = if fromTop then -1 else 1
	return UDim2.new(
		rest.X.Scale,
		rest.X.Offset,
		rest.Y.Scale,
		rest.Y.Offset + direction * (1 - alpha) * offset
	)
end

function DeathFrame:Construct()
	self._scope = Fusion.scoped({
		Value = Fusion.Value,
		Computed = Fusion.Computed,
		Hydrate = Fusion.Hydrate,
		Spring = Fusion.Spring,
		Observer = Fusion.Observer,
	})

	self._visible = self._scope:Value(false)
	self._gameEndCountdown = self._scope:Value(nil :: number?)
	self._characterTrove = nil
	self._screenGui = nil
	self._restBackgroundTransparency = 1
	self._restStates = {}

	self.Instance.Visible = true
end

function DeathFrame:_rememberRestState(instance: Instance, key: string, value: any)
	if self._restStates[instance] == nil then
		self._restStates[instance] = {}
	end

	if self._restStates[instance][key] == nil then
		self._restStates[instance][key] = value
	end
end

function DeathFrame:_getRestState(instance: Instance, key: string): any
	return self._restStates[instance] and self._restStates[instance][key]
end

function DeathFrame:_captureRestStates()
	for _, descendant in self.Instance:GetDescendants() do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			self:_rememberRestState(descendant, "TextTransparency", descendant.TextTransparency)
		end

		if descendant:IsA("GuiObject") then
			self:_rememberRestState(descendant, "BackgroundTransparency", descendant.BackgroundTransparency)
		end

		if descendant:IsA("UIStroke") then
			self:_rememberRestState(descendant, "Transparency", descendant.Transparency)
		end

		if descendant:IsA("UIGradient") then
			self:_rememberRestState(descendant, "Enabled", descendant.Enabled)
		end
	end
end

function DeathFrame:_getVisibleRestTransparency(instance: Instance, key: string): number
	local rest = self:_getRestState(instance, key)
	if rest == nil or rest >= 1 then
		return 0
	end

	return rest
end

function DeathFrame:_lerpHiddenTransparency(rest: number, progress: number): number
	return rest + (1 - progress) * (1 - rest)
end

function DeathFrame:_applyHiddenState()
	for _, descendant in self.Instance:GetDescendants() do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			descendant.TextTransparency = 1
		end

		if descendant:IsA("TextButton") then
			descendant.BackgroundTransparency = 1
		end

		if descendant:IsA("UIStroke") then
			descendant.Transparency = 1
		end

		if descendant:IsA("UIGradient") then
			descendant.Enabled = false
		end
	end
end

function DeathFrame:_hydrateStroke(stroke: UIStroke, alpha)
	local restStrokeTransparency = self:_getVisibleRestTransparency(stroke, "Transparency")

	self._scope:Hydrate(stroke)({
		Transparency = self._scope:Computed(function(use)
			return self:_lerpHiddenTransparency(restStrokeTransparency, use(alpha))
		end),
	})
end

function DeathFrame:_staggeredAlpha(openAmount, delay: number, span: number)
	return self._scope:Computed(function(use)
		local amount = use(openAmount)
		return math.clamp((amount - delay) / span, 0, 1)
	end)
end

function DeathFrame:_hydrateLabel(label: TextLabel, openAmount, delay: number, slideOffset: number, fromTop: boolean?)
	local rest = label.Position
	local restTextTransparency = self:_getVisibleRestTransparency(label, "TextTransparency")
	local alpha = self:_staggeredAlpha(openAmount, delay, 0.18)

	self._scope:Hydrate(label)({
		TextTransparency = self._scope:Computed(function(use)
			return self:_lerpHiddenTransparency(restTextTransparency, use(alpha))
		end),
		Position = self._scope:Spring(
			self._scope:Computed(function(use)
				return offsetPosition(rest, use(alpha), slideOffset, fromTop)
			end),
			SHOW_SPRING_SPEED,
			SHOW_SPRING_DAMPING
		),
	})

	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		self:_hydrateStroke(stroke, alpha)
	end
end

function DeathFrame:_hydrateButton(button: TextButton, openAmount, delay: number, slideOffset: number)
	local rest = button.Position
	local restBackgroundTransparency = self:_getRestState(button, "BackgroundTransparency") or button.BackgroundTransparency
	local restTextTransparency = self:_getVisibleRestTransparency(button, "TextTransparency")
	local alpha = self:_staggeredAlpha(openAmount, delay, 0.2)

	self._scope:Hydrate(button)({
		BackgroundTransparency = self._scope:Computed(function(use)
			return self:_lerpHiddenTransparency(restBackgroundTransparency, use(alpha))
		end),
		TextTransparency = self._scope:Computed(function(use)
			return self:_lerpHiddenTransparency(restTextTransparency, use(alpha))
		end),
		Position = self._scope:Spring(
			self._scope:Computed(function(use)
				return offsetPosition(rest, use(alpha), slideOffset)
			end),
			SHOW_SPRING_SPEED,
			SHOW_SPRING_DAMPING
		),
	})

	for _, descendant in button:GetDescendants() do
		if descendant:IsA("TextLabel") then
			self:_hydrateLabel(descendant, openAmount, delay, slideOffset)
		elseif descendant:IsA("UIStroke") then
			self:_hydrateStroke(descendant, alpha)
		end
	end

	local gradient = button:FindFirstChildOfClass("UIGradient")
	if gradient then
		self._scope:Hydrate(gradient)({
			Enabled = self._scope:Computed(function(use)
				return use(alpha) > 0.01
			end),
		})
	end
end

function DeathFrame:_hydrateCountdownLabel(timer: TextLabel, openAmount)
	local rest = timer.Position
	local restTextTransparency = self:_getVisibleRestTransparency(timer, "TextTransparency")
	local openAlpha = self:_staggeredAlpha(openAmount, 0.16, 0.18)
	local countdownAlpha = self._scope:Computed(function(use)
		if use(self._gameEndCountdown) == nil then
			return 0
		end

		return use(openAlpha)
	end)

	self._scope:Hydrate(timer)({
		Text = self._scope:Computed(function(use)
			local countdown = use(self._gameEndCountdown)
			if countdown == nil then
				return ""
			end

			return `GAME ENDING IN {countdown} SECONDS`
		end),
		TextTransparency = self._scope:Computed(function(use)
			return self:_lerpHiddenTransparency(restTextTransparency, use(countdownAlpha))
		end),
		Position = self._scope:Spring(
			self._scope:Computed(function(use)
				return offsetPosition(rest, use(countdownAlpha), SLIDE_OFFSET + 8)
			end),
			SHOW_SPRING_SPEED,
			SHOW_SPRING_DAMPING
		),
	})

	local stroke = timer:FindFirstChildOfClass("UIStroke")
	if stroke then
		self:_hydrateStroke(stroke, countdownAlpha)
	end
end

function DeathFrame:HydrateUI()
	self._screenGui = self.Instance:FindFirstAncestorOfClass("ScreenGui")
	self._restBackgroundTransparency = self.Instance.BackgroundTransparency

	local title = self.Instance:WaitForChild("Title") :: TextLabel
	local revive = self.Instance:WaitForChild("Revive") :: TextButton

	self:_captureRestStates()
	self:_applyHiddenState()

	local openAmount = self._scope:Spring(
		self._scope:Computed(function(use)
			return use(self._visible) and 1 or 0
		end),
		SHOW_SPRING_SPEED,
		SHOW_SPRING_DAMPING
	)

	self._scope:Hydrate(self.Instance)({
		BackgroundTransparency = self._scope:Computed(function(use)
			local alpha = use(openAmount)
			return 1 - alpha * (1 - self._restBackgroundTransparency)
		end),
	})

	local superTitle = self.Instance:FindFirstChild("SuperTitle")
	if superTitle and superTitle:IsA("TextLabel") then
		self:_hydrateLabel(superTitle, openAmount, 0, 48, true)
	end

	self:_hydrateLabel(title, openAmount, if superTitle then 0.08 else 0, if superTitle then 64 else 48, true)

	local timer = self.Instance:FindFirstChild("Timer")
	if timer and timer:IsA("TextLabel") then
		self:_hydrateCountdownLabel(timer, openAmount)
	end

	local reviveTitle = self.Instance:FindFirstChild("ReviveTitle")
	if reviveTitle and reviveTitle:IsA("TextLabel") then
		self:_hydrateLabel(reviveTitle, openAmount, 0.24, SLIDE_OFFSET + 12)
	end

	self:_hydrateButton(revive, openAmount, 0.24, SLIDE_OFFSET + 16)

	self._trove:Add(revive.Activated:Connect(function()
		if not Fusion.peek(self._visible) then
			return
		end

		Knit.GetService("ReviveService"):SelfRevive()
	end))

	if self._screenGui then
		self._trove:Add(self._scope:Observer(openAmount):onChange(function()
			if Fusion.peek(self._visible) then
				return
			end

			if Fusion.peek(openAmount) <= 0.01 then
				self._screenGui.Enabled = false
				self:_applyHiddenState()
			end
		end))
	end
end

function DeathFrame:SetVisible(isVisible: boolean)
	if self._screenGui then
		if isVisible then
			self._screenGui.Enabled = true
		end
	end

	self._visible:set(isVisible)

	if not isVisible then
		self:_applyHiddenState()
	end
end

function DeathFrame:_clearCharacterTrove()
	if self._characterTrove then
		self._characterTrove:Destroy()
		self._characterTrove = nil
	end
end

function DeathFrame:_bindCharacter(character: Model)
	self:_clearCharacterTrove()

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	self._characterTrove = self._trove:Extend()
	self._characterTrove:Add(humanoid.Died:Connect(function()
		self:SetVisible(true)
	end))
end

function DeathFrame:Start()
	self:HydrateUI()
	self:SetVisible(false)

	self._trove:Add(Knit.GetService("ReviveService").GameEndCountdown:Observe(function(countdown: number?)
		self._gameEndCountdown:set(countdown)
	end))

	local player = Players.LocalPlayer

	local function onCharacterAdded(character: Model)
		self:SetVisible(false)
		self:_bindCharacter(character)
	end

	if player.Character then
		onCharacterAdded(player.Character)
	end

	self._trove:Add(player.CharacterAdded:Connect(onCharacterAdded))
end

function DeathFrame:Stop()
	self:_clearCharacterTrove()
	Fusion.doCleanup(self._scope)
end

return DeathFrame
