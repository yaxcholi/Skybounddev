local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local AmmoTypeData = require(ReplicatedStorage.Data.AmmoType)
local WeaponsData = require(ReplicatedStorage.Data.Weapons)

local LootService = Knit.CreateService({
	Name = "LootService",
	Client = {},
})

local function prepareModelPhysics(model: Model)
	local handle = model:FindFirstChild("Handle") :: BasePart?

	for _, descendant in model:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end

		if handle and descendant ~= handle then
			local existingWeld = descendant:FindFirstChildWhichIsA("WeldConstraint")
			if not existingWeld then
				local weldConstraint = Instance.new("WeldConstraint")
				weldConstraint.Part0 = handle
				weldConstraint.Part1 = descendant
				weldConstraint.Parent = descendant
			end
		end

		descendant.Anchored = false
		descendant.CanCollide = true
	end

	if handle then
		model.PrimaryPart = handle
	end
end

local function createModelFromTool(tool: Tool): Model
	local model = Instance.new("Model")
	model.Name = tool.Name

	for _, child in tool:GetChildren() do
		child.Parent = model
	end

	tool:Destroy()
	prepareModelPhysics(model)

	return model
end

function LootService:InferItemType(itemName: string): string
	if WeaponsData[itemName] then
		return "Weapon"
	end

	if AmmoTypeData[itemName] then
		return "AmmoType"
	end

	return "Weapon"
end

function LootService:GetDefaultAmmoAmount(ammoTypeName: string): number
	local ammoData = AmmoTypeData[ammoTypeName]
	if not ammoData then
		return 0
	end

	return ammoData.Amount or 0
end

function LootService:CreateWorldLoot(itemName: string, itemType: string, pivot: CFrame, attributes: { [string]: any }?): Model
	local tool = ServerStorage.Assets.Tools:FindFirstChild(itemName)
	if not tool then
		error(`Tool {itemName} not found`)
	end

	local model = createModelFromTool(tool:Clone())
	model:SetAttribute("Type", itemType)
	model:SetAttribute("ItemName", itemName)
	if attributes then
		for attributeName, value in attributes do
			model:SetAttribute(attributeName, value)
		end
	end

	if itemType == "AmmoType" and model:GetAttribute("AmmoAmount") == nil then
		model:SetAttribute("AmmoAmount", self:GetDefaultAmmoAmount(itemName))
	end

	model:AddTag("Collectable")
	model:PivotTo(pivot)
	model.Parent = workspace

	return model
end

function LootService:KnitStart() end

function LootService:KnitInit() end

return LootService
