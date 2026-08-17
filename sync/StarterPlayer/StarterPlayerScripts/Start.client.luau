local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Packages.Loader)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Systems = script.Parent:WaitForChild("Systems")

Loader.SpawnAll(Loader.LoadDescendants(Systems, Loader.MatchesName("Controller$")))

Knit.Start():catch(warn)

-- load components
for _, module in Systems:GetDescendants() do
	if module:IsA("ModuleScript") then
		task.spawn(function()
			require(module)
		end)
	end
end

