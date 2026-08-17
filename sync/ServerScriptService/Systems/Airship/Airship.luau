local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Timer = require(ReplicatedStorage.Packages.Timer)

local Airship = Component.new({ Tag = "Airship", Extensions = { TroveAdder, RemoteComponent } })

function Airship:Construct()
	self._scope = Fusion.scoped({
		Value = Fusion.Value,
	})

	self.EnemyOnBoard = self._scope:Value(false)
end

function Airship:Start()
	self:Weld()

	local playerZone = self.Instance:WaitForChild("PlayerZone") :: BasePart

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	self._trove:Add(Timer.Simple(0.2, function()
		local filter = {}

		for _, ai in CollectionService:GetTagged("EnemyAI") do
			local humanoid = ai:WaitForChild("Humanoid")
			if humanoid.Health > 0 then
				table.insert(filter, ai)
			end
		end

		overlapParams.FilterDescendantsInstances = filter

		local enemyOnBoard = #workspace:GetPartsInPart(playerZone, overlapParams) > 0

		if Fusion.peek(self.EnemyOnBoard) ~= enemyOnBoard then
			self.EnemyOnBoard:set(enemyOnBoard)
		end
	end))
end

function Airship:Weld()
	for _, v in self.Instance:GetDescendants() do
		if not v:IsA("BasePart") then
			continue
		end

		if v:HasTag("WeldIgnore") then
			v.Anchored = false
			continue
		end

		local wc = Instance.new("WeldConstraint")
		wc.Part0 = self.Instance.PrimaryPart
		wc.Part1 = v
		wc.Parent = v

		v.Anchored = false
	end
end

function Airship:Stop() end

return Airship
