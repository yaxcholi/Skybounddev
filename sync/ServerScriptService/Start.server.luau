local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Loader = require(ReplicatedStorage.Packages.Loader)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Systems = ServerScriptService.Systems

Loader.SpawnAll(Loader.LoadDescendants(Systems, Loader.MatchesName("Service$")))

Knit.Start():catch(warn)

-- load components
for _, module in Systems:GetDescendants() do
	if module:IsA("ModuleScript") then
		task.spawn(function()
			require(module)
		end)
	end
end
