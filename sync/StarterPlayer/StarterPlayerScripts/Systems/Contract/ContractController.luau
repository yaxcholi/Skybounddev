local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local ContractConfig = require(ReplicatedStorage.Data.ContractConfig)

local TITLE_FONT = Font.new("rbxasset://fonts/families/AccanthisADFStd.json", Enum.FontWeight.Bold)
local BODY_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)
local SPRING_SPEED = 22
local SPRING_DAMP = 0.85
local GOLD = Color3.fromRGB(212, 175, 55)
local DANGER_STAR = Color3.fromRGB(220, 60, 100)
local CARD_DARK = Color3.fromRGB(28, 20, 12)
local PARCHMENT = Color3.fromRGB(232, 218, 182)
local BONUS_BG = Color3.fromRGB(38, 28, 18)

local ContractController = Knit.CreateController({ Name = "ContractController" })

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = parent
end

local function stroke(parent, col, thick)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = thick or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	for k, v in props do l[k] = v end
	l.Parent = parent
	return l
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in props do f[k] = v end
	f.Parent = parent
	return f
end

function ContractController:KnitInit() end

function ContractController:KnitStart()
	local scope = Fusion.scoped({
		Value = Fusion.Value,
		Computed = Fusion.Computed,
		Spring = Fusion.Spring,
		Hydrate = Fusion.Hydrate,
		Observer = Fusion.Observer,
	})

	local visible = scope:Value(false)
	local votes = scope:Value({})
	local phase = scope:Value("Hidden")
	local myVote = scope:Value(nil)
	local cardsFrame = nil

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg = Instance.new("ScreenGui")
	sg.Name = "ContractScreen"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.IgnoreGuiInset = true
	sg.Enabled = false
	sg.Parent = playerGui

	local root = frame(sg, {
		Name = "Root",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	})

	local titleLbl = label(root, {
		Text = "CHOOSE YOUR CONTRACT",
		TextColor3 = GOLD,
		TextSize = 30,
		FontFace = TITLE_FONT,
		Size = UDim2.new(1, 0, 0, 56),
		Position = UDim2.new(0, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
	})
	stroke(titleLbl, Color3.fromRGB(0, 0, 0), 1.5)

	scope:Observer(scope:Computed(function(use) return use(visible) end)):onChange(function()
		if not Fusion.peek(visible) then
			task.delay(0.05, function()
				if not Fusion.peek(visible) then
					sg.Enabled = false
				end
			end)
		end
	end)

	local toggleSg = Instance.new("ScreenGui")
	toggleSg.Name = "ContractToggleSg"
	toggleSg.ResetOnSpawn = false
	toggleSg.IgnoreGuiInset = true
	toggleSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	toggleSg.Parent = playerGui

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ContractToggle"
	toggleBtn.Size = UDim2.new(0, 138, 0, 32)
	toggleBtn.Position = UDim2.new(1, -150, 0.5, 8)
	toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(38, 28, 18)
	toggleBtn.TextColor3 = GOLD
	toggleBtn.TextSize = 13
	toggleBtn.FontFace = TITLE_FONT
	toggleBtn.Text = "CONTRACTS ▸"
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Visible = false
	toggleBtn.ZIndex = 10
	corner(toggleBtn, 6)
	stroke(toggleBtn, GOLD, 1)
	toggleBtn.Parent = toggleSg

	toggleBtn.Activated:Connect(function()
		if Fusion.peek(phase) == "Hidden" then return end
		local next = not Fusion.peek(visible)
		if next then sg.Enabled = true end
		visible:set(next)
		toggleBtn.Text = if next then "CONTRACTS ◂" else "CONTRACTS ▸"
	end)

	local function buildCard(contract, parent)
		local fc = ContractConfig.FACTION_COLORS[contract.faction]

		local card = frame(parent, {
			Size = UDim2.new(0, 276, 1, 0),
			BackgroundColor3 = CARD_DARK,
		})
		corner(card, 8)
		stroke(card, GOLD, 2)

		local top = frame(card, {
			Size = UDim2.new(1, 0, 0, 86),
			BackgroundColor3 = fc,
		})
		corner(top, 8)

		local fn = label(top, {
			Text = string.upper(contract.faction),
			TextColor3 = GOLD,
			TextSize = 24,
			FontFace = TITLE_FONT,
			Size = UDim2.new(1, 0, 0, 34),
			Position = UDim2.new(0, 0, 1, -34),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		stroke(fn, Color3.fromRGB(0,0,0), 1.5)

		local starsRow = frame(top, {
			Size = UDim2.new(1, -8, 0, 22),
			Position = UDim2.new(0, 4, 0, 4),
			BackgroundTransparency = 1,
		})
		local sl = Instance.new("UIListLayout")
		sl.FillDirection = Enum.FillDirection.Horizontal
		sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
		sl.VerticalAlignment = Enum.VerticalAlignment.Center
		sl.Padding = UDim.new(0, 2)
		sl.Parent = starsRow

		for i = 1, contract.stars + contract.dangerStars do
			label(starsRow, {
				Text = "★",
				TextColor3 = if i > contract.stars then DANGER_STAR else GOLD,
				TextSize = 15,
				FontFace = TITLE_FONT,
				Size = UDim2.new(0, 17, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
			})
		end

		label(card, {
			Text = "Destination",
			TextColor3 = Color3.fromRGB(130, 110, 75),
			TextSize = 10,
			FontFace = BODY_FONT,
			Size = UDim2.new(1, -12, 0, 14),
			Position = UDim2.new(0, 6, 0, 92),
			TextXAlignment = Enum.TextXAlignment.Center,
		})

		label(card, {
			Text = contract.destination,
			TextColor3 = Color3.fromRGB(38, 26, 12),
			TextSize = 16,
			FontFace = TITLE_FONT,
			Size = UDim2.new(1, -12, 0, 28),
			Position = UDim2.new(0, 6, 0, 106),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextWrapped = true,
		})

		local parch = frame(card, {
			Size = UDim2.new(1, -16, 0, 88),
			Position = UDim2.new(0, 8, 0, 138),
			BackgroundColor3 = PARCHMENT,
		})
		corner(parch, 4)
		label(parch, {
			Text = contract.description,
			TextColor3 = Color3.fromRGB(48, 32, 16),
			TextSize = 11,
			FontFace = BODY_FONT,
			Size = UDim2.new(1, -10, 1, -8),
			Position = UDim2.new(0, 5, 0, 4),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
		})

		local bonusText = ""
		for _, item in contract.bonus do
			bonusText ..= (if bonusText == "" then "" else "\n") .. item.name .. "  ×" .. item.quantity
		end

		local bonusSec = frame(card, {
			Size = UDim2.new(1, 0, 0, 72),
			Position = UDim2.new(0, 0, 1, -72),
			BackgroundColor3 = BONUS_BG,
		})
		corner(bonusSec, 8)
		label(bonusSec, {
			Text = "SIGNING BONUS",
			TextColor3 = Color3.fromRGB(180, 175, 160),
			TextSize = 10,
			FontFace = TITLE_FONT,
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.new(0, 0, 0, 4),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		label(bonusSec, {
			Text = bonusText,
			TextColor3 = GOLD,
			TextSize = 12,
			FontFace = BODY_FONT,
			Size = UDim2.new(1, -8, 1, -26),
			Position = UDim2.new(0, 4, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
		})

		local modLines = {}
		if contract.modifiers then
			local ef = contract.modifiers.enemyFrequencyMultiplier
			local wi = contract.modifiers.weatherIntensity
			if ef then
				local arrow = if ef > 1 then "↑" else if ef < 1 then "↓" else "→"
				table.insert(modLines, arrow .. " Enemies ×" .. string.format("%.1f", ef))
			end
			if wi then
				local arrow = if wi > 1 then "↑" else if wi < 1 then "↓" else "→"
				table.insert(modLines, arrow .. " Weather ×" .. string.format("%.1f", wi))
			end
		end

		if #modLines > 0 then
			label(card, {
				Text = table.concat(modLines, "   "),
				TextColor3 = Color3.fromRGB(170, 155, 110),
				TextSize = 10,
				FontFace = BODY_FONT,
				Size = UDim2.new(1, -12, 0, 18),
				Position = UDim2.new(0, 6, 1, -116),
				TextXAlignment = Enum.TextXAlignment.Center,
			})
		end

		local voteCountLabel = label(card, {
			TextColor3 = Color3.fromRGB(195, 175, 115),
			TextSize = 12,
			FontFace = BODY_FONT,
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 1, -96),
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = "",
		})

		local voteCount = scope:Computed(function(use)
			local n = 0
			for _, f in use(votes) do
				if f == contract.faction then n += 1 end
			end
			return n
		end)

		local isMyVote = scope:Computed(function(use)
			return use(myVote) == contract.faction
		end)

		scope:Hydrate(voteCountLabel)({
			Text = scope:Computed(function(use)
				local n = use(voteCount)
				return if n == 0 then "" else (n .. if n == 1 then " vote" else " votes")
			end),
		})

		scope:Hydrate(card)({
			BackgroundColor3 = scope:Computed(function(use)
				return if use(isMyVote) then Color3.fromRGB(52, 40, 18) else CARD_DARK
			end),
		})

		local voteBtn = Instance.new("TextButton")
		voteBtn.Size = UDim2.new(1, -16, 0, 30)
		voteBtn.Position = UDim2.new(0, 8, 1, -38)
		voteBtn.BackgroundColor3 = fc
		voteBtn.TextColor3 = Color3.fromRGB(255, 240, 200)
		voteBtn.TextSize = 13
		voteBtn.FontFace = TITLE_FONT
		voteBtn.BorderSizePixel = 0
		voteBtn.Text = "VOTE"
		voteBtn.Parent = card
		corner(voteBtn, 6)

		scope:Hydrate(voteBtn)({
			Text = scope:Computed(function(use)
				return if use(isMyVote) then "✓  VOTED" else "VOTE"
			end),
		})

		voteBtn.Activated:Connect(function()
			if Fusion.peek(phase) ~= "Voting" then return end
			myVote:set(contract.faction)
			Knit.GetService("ContractService"):VoteContract(contract.faction)
		end)
	end

	local function rebuildCards(contracts)
		if cardsFrame then
			cardsFrame:Destroy()
			cardsFrame = nil
		end

		local cf = frame(root, {
			Name = "CardsFrame",
			Size = UDim2.new(1, -60, 1, -130),
			Position = UDim2.new(0, 30, 0, 100),
			BackgroundTransparency = 1,
		})

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 20)
		layout.Parent = cf

		cardsFrame = cf

		for _, contract in contracts do
			buildCard(contract, cf)
		end
	end

	local contractService = Knit.GetService("ContractService")

	contractService.Phase:Observe(function(p: string)
		phase:set(p)

		if p == "Voting" then
			local contracts = contractService.Contracts:Get()
			myVote:set(nil)
			rebuildCards(contracts)
			toggleBtn.Text = "CONTRACTS"
			toggleBtn.Visible = true
			sg.Enabled = true
			visible:set(true)
		elseif p == "Selected" then
			toggleBtn.Visible = false
			task.delay(1.2, function()
				visible:set(false)
			end)
		elseif p == "Hidden" then
			toggleBtn.Visible = false
			visible:set(false)
		end
	end)

	contractService.Votes:Observe(function(v)
		votes:set(v)
	end)
end

return ContractController
