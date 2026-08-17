local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Knit = require(ReplicatedStorage.Packages.Knit)

local DROP_DISTANCE = 4
local DROP_RAY_DISTANCE = 50

local CanBeDropped = Component.new({ Tag = "CanBeDropped", Extensions = { TroveAdder, RemoteComponent } })
CanBeDropped.Client = {
	Drop = Knit.CreateSignal(),
}

local function getDropPosition(character: Model, tool: Tool): Vector3
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local lookVector = Vector3.new(humanoidRootPart.CFrame.LookVector.X, 0, humanoidRootPart.CFrame.LookVector.Z)

	if lookVector.Magnitude > 0 then
		lookVector = lookVector.Unit
	else
		lookVector = humanoidRootPart.CFrame.LookVector
	end

	local rayOrigin = humanoidRootPart.Position + lookVector * DROP_DISTANCE + Vector3.new(0, 2, 0)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character, tool }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(rayOrigin, Vector3.new(0, -DROP_RAY_DISTANCE, 0), params)
	if result then
		return result.Position
	end

	return humanoidRootPart.Position + lookVector * DROP_DISTANCE
end

function CanBeDropped:Construct() end

function CanBeDropped:Start()
	self._trove:Add(self.Client.Drop:Connect(function(player: Player)
		self:Drop(player)
	end))
end

function CanBeDropped:Drop(player: Player)
	local tool = self.Instance
	local character = player.Character

	if not character or tool.Parent ~= character then
		return
	end

	local lootService = Knit.GetService("LootService")
	local itemName = tool:GetAttribute("ItemName") or tool.Name
	local itemType = tool:GetAttribute("Type") or lootService:InferItemType(itemName)
	local dropPosition = getDropPosition(character, tool)
	local attributes: { [string]: any } = {}
	if itemType == "AmmoType" then
		attributes.AmmoAmount = tool:GetAttribute("AmmoAmount") or lootService:GetDefaultAmmoAmount(itemName)
	elseif itemType == "Weapon" then
		attributes.CurrentClip = tool:GetAttribute("CurrentClip") or 0
	end

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local pivotOffset = if handle then handle.Size.Y * 0.5 else 1

	tool:Destroy()
	lootService:CreateWorldLoot(itemName, itemType, CFrame.new(dropPosition + Vector3.new(0, pivotOffset, 0)), attributes)
end

function CanBeDropped:Stop() end

return CanBeDropped
