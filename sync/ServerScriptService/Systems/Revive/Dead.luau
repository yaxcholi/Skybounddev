local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Knit = require(ReplicatedStorage.Packages.Knit)

local HoldInteractable = require(script.Parent.Parent.Interactions.HoldInteractable)

local Dead = Component.new({ Tag = "Dead", Extensions = { TroveAdder } })

function Dead:Construct()
	self._scope = Fusion.scoped({
		New = Fusion.New,
		Children = Fusion.Children,
	})
end

function Dead:Start()
	local head = self.Instance:FindFirstChild("Head") or self.Instance:WaitForChild("HumanoidRootPart") :: BasePart
	local player = Players:GetPlayerFromCharacter(self.Instance)
	local displayName = if player then player.DisplayName else "Unknown"

	self.Instance:AddTag("HoldInteractable")
	self.Instance:SetAttribute("HoldDuration", 3)
	self.Instance:SetAttribute("InteractionPrompt", "Revive")
	self.Instance:SetAttribute("RequiredTool", "Bandage")
	self.Instance:SetAttribute("Range", 10)

	HoldInteractable:WaitForInstance(self.Instance):andThen(function(holdInteractable)
		self._trove:Add(holdInteractable.OnHoldComplete:Connect(function(reviver: Player)
			local target = Players:GetPlayerFromCharacter(self.Instance)
			if target then
				Knit.GetService("ReviveService"):TeamRevive(reviver, target)
			end
		end))
	end)

	self._scope:New("BillboardGui")({
		Name = "DeadPrompt",
		Size = UDim2.fromOffset(200, 52),
		StudsOffset = Vector3.new(0, 2, 0),
		AlwaysOnTop = true,
		MaxDistance = 100,
		Adornee = head,
		Parent = head,

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
						Name = "PlayerName",
						LayoutOrder = 1,
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						Size = UDim2.new(1, 0, 0, 22),
						Text = displayName,
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,

						[Fusion.Children] = {
							self._scope:New("UIStroke")({
								Name = "UIStroke",
								Thickness = 2,
							}),
						},
					}),

					self._scope:New("TextLabel")({
						Name = "Status",
						LayoutOrder = 2,
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						Size = UDim2.new(1, 0, 0, 22),
						Text = "DEAD",
						TextColor3 = Color3.fromRGB(255, 90, 90),
						TextScaled = true,

						[Fusion.Children] = {
							self._scope:New("UIStroke")({
								Name = "UIStroke",
								Thickness = 2,
							}),
						},
					}),
				},
			}),
		},
	})
end

function Dead:Stop()
	self.Instance:RemoveTag("HoldInteractable")
	Fusion.doCleanup(self._scope)
end

return Dead
