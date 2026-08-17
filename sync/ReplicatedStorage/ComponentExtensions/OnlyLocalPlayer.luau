local player = game:GetService("Players").LocalPlayer

local OnlyLocalPlayer = {}

function OnlyLocalPlayer.ShouldConstruct(component)
	local ownerId = component.Instance:GetAttribute("OwnerId")
	return ownerId == player.UserId
end

return OnlyLocalPlayer
