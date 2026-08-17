local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local UIVisibilityController = Knit.CreateController({ Name = "UIVisibilityController" })

local scope = Fusion.scoped({
	Value = Fusion.Value,
})

local activeGroup = scope:Value("Lobby")
local previousGroup = nil
local groupValues = {}

function UIVisibilityController:KnitStart() end

function UIVisibilityController:KnitInit() end

function UIVisibilityController:RegisterFrame(groups: string | { string }, value)
	local function addValue(group: string)
		if not groupValues[group] then
			groupValues[group] = {}
		end

		table.insert(groupValues[group], value)
	end

	if type(groups) == "string" then
		addValue(groups)
		if Fusion.peek(activeGroup) == groups then
			value:set(true)
		end
	else
		for _, group in groups do
			addValue(group)
			if Fusion.peek(activeGroup) == group then
				value:set(true)
			end
		end
	end
end

function UIVisibilityController:SetGroupActive(group: string)
	local currentActiveGroup = Fusion.peek(activeGroup)

	activeGroup:set(group)

	if groupValues[currentActiveGroup] then
		for _, value in groupValues[currentActiveGroup] do
			value:set(false)
		end
	end

	if groupValues[group] then
		for _, value in groupValues[group] do
			value:set(true)
		end
	end

	previousGroup = currentActiveGroup
end

function UIVisibilityController:GetActiveGroup()
	return Fusion.peek(activeGroup)
end

function UIVisibilityController:RestorePreviousGroup()
	if not previousGroup then
		previousGroup = "Lobby"
	end
	
	activeGroup:set(previousGroup)
end

return UIVisibilityController
