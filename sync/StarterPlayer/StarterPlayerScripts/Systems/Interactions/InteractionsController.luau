local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Collectable = require(script.Parent.Collectable)
local HoldInteractable = require(script.Parent.HoldInteractable)
local Interactable = require(script.Parent.Interactable)

local InteractionsController = Knit.CreateController { Name = "InteractionsController" }

local INTERACT_RANGE = 10

local function setAllNear(items, value)
	for _, item in items do
		item:SetNear(value)
	end
end

local function setAllCanInteract(items, value)
	for _, item in items do
		item:SetCanInteract(value)
	end
end

local function getNearestInteract(collectables, interactables, position, maxRange: number?)
	local nearestItem = nil
	local nearestDistance = math.huge

	local function consider(items)
		for _, item in items do
			if item.IsTargetable and not item:IsTargetable() then
				continue
			end

			local distance = item:GetDistance(position)
			local range = maxRange or item._range

			if distance <= range and distance < nearestDistance then
				nearestItem = item
				nearestDistance = distance
			end
		end
	end

	consider(collectables)
	consider(interactables)

	return nearestItem
end

local function updateNearByRange(items, position)
	for _, item in items do
		if item.IsTargetable and not item:IsTargetable() then
			item:SetNear(false)
			continue
		end

		item:SetNear(item:GetDistance(position) <= item._range)
	end
end

function InteractionsController:KnitStart()
	Timer.Simple(0.2, function()
		local character = Players.LocalPlayer.Character
		local collectables = Collectable:GetAll()
		local holdInteractables = HoldInteractable:GetAll()
		local interactables = Interactable:GetAll()

		if not character then
			setAllNear(collectables, false)
			setAllNear(holdInteractables, false)
			setAllNear(interactables, false)
			setAllCanInteract(collectables, false)
			setAllCanInteract(holdInteractables, false)
			setAllCanInteract(interactables, false)
			return
		end

		local position = character:GetPivot().Position
		local nearestInteract = getNearestInteract(collectables, interactables, position, INTERACT_RANGE)
		local nearestHold = getNearestInteract(holdInteractables, {}, position, INTERACT_RANGE)

		updateNearByRange(collectables, position)
		updateNearByRange(holdInteractables, position)
		updateNearByRange(interactables, position)
		setAllCanInteract(collectables, false)
		setAllCanInteract(holdInteractables, false)
		setAllCanInteract(interactables, false)

		local activeHold = nil
		for _, item in holdInteractables do
			if item:IsHolding() then
				activeHold = item
				break
			end
		end

		if activeHold then
			activeHold:SetCanInteract(true)
		elseif nearestHold then
			nearestHold:SetCanInteract(true)
		elseif nearestInteract then
			nearestInteract:SetCanInteract(true)
		end
	end)
end


function InteractionsController:KnitInit()
	
end


return InteractionsController
