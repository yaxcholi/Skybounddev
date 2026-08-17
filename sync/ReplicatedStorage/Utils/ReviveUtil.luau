local ReviveUtil = {}

local function getToolName(tool: Tool): string
	return tool:GetAttribute("ItemName") or tool.Name
end

function ReviveUtil.isBandageTool(tool: Tool): boolean
	if tool:HasTag("Bandage") then
		return true
	end

	if tool:GetAttribute("Type") == "Bandage" then
		return true
	end

	return string.find(string.lower(getToolName(tool)), "bandage") ~= nil
end

function ReviveUtil.hasBandageEquipped(character: Model): boolean
	local tool = character:FindFirstChildWhichIsA("Tool")
	return tool ~= nil and ReviveUtil.isBandageTool(tool)
end

function ReviveUtil.hasRequiredToolEquipped(character: Model, requiredTool: string): boolean
	if requiredTool == "Bandage" then
		return ReviveUtil.hasBandageEquipped(character)
	end

	local tool = character:FindFirstChildWhichIsA("Tool")
	if not tool then
		return false
	end

	return getToolName(tool) == requiredTool
end

return ReviveUtil
