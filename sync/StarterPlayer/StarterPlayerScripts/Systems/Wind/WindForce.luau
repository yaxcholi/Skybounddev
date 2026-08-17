local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)

local WindForce = Component.new({ Tag = "WindForce", Extensions = { TroveAdder } })

-- Wind effect parameters
local WIND_STRENGTH_MULTIPLIER = 1
local RANDOMNESS_STRENGTH = 1
local UPDATE_FREQUENCY = 0.1 -- Update every 0.1 seconds

local lastUpdateTime = 0
local randomOffset = Vector3.new(0, 0, 0)

function WindForce:Construct()
	self.vectorForce = self.Instance:FindFirstChild("VectorForce", true)
	if not self.vectorForce then
		warn("WindForce component requires a VectorForce child")
		return
	end

	-- Initialize random offset
	randomOffset = Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)).Unit * RANDOMNESS_STRENGTH
end

function WindForce:Start()
	if not self.vectorForce then
		return
	end

	-- Connect to RunService to update wind force
	self._trove:Add(RunService.Heartbeat:Connect(function(deltaTime)
		self:UpdateWindForce(deltaTime)
	end))
end

function WindForce:Stop()
	-- Cleanup is handled by Trove
end

function WindForce:UpdateWindForce(deltaTime)
	if not self.vectorForce then
		return
	end

	-- Update at specified frequency
	lastUpdateTime = lastUpdateTime + deltaTime
	if lastUpdateTime < UPDATE_FREQUENCY then
		return
	end
	lastUpdateTime = 0

	-- Get global wind from workspace
	local globalWind = workspace.GlobalWind or Vector3.new(0, 0, 0)

	-- Apply wind strength multiplier
	local baseWindForce = globalWind * WIND_STRENGTH_MULTIPLIER

	-- Add randomness to create natural wind movement
	local randomWind = randomOffset * math.sin(tick() * 2) * RANDOMNESS_STRENGTH * globalWind.Magnitude
	-- Combine base wind with random component
	local finalWindForce = baseWindForce + randomWind

	-- Apply to VectorForce
	self.vectorForce.Force = finalWindForce
end

return WindForce
