local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Knit = require(ReplicatedStorage.Packages.Knit)

local random = Random.new()

local Downed = Component.new({ Tag = "Downed", Extensions = { TroveAdder } })

function Downed:Construct()
	local isLeft = random:NextNumber() < 0.5
	local xOffset = isLeft and random:NextNumber(-80, -30) or random:NextNumber(30, 80)

	self._offset = Vector3.new(xOffset, random:NextNumber(10, 50), random:NextNumber(-50, 50))
end

function Downed:Start()
	local asset = self._trove:Add(ServerStorage.Assets.Downed:Clone())
	local highlight = self._trove:Add(ServerStorage.Assets.DeadHighlight:Clone())
	asset:PivotTo(self.Instance:GetPivot())

	asset.Parent = workspace
	highlight.Parent = self.Instance
	asset.RopePart.RopeConstraint.Attachment0 = self.Instance.RightFoot.RightFootAttachment

	local humanoid = self.Instance:WaitForChild("Humanoid")
	humanoid.Health = -math.huge

	self:UpdatePosition()

	self._asset = asset
end

function Downed:SteppedUpdate()
	self:UpdatePosition()
end

function Downed:Stop() end

function Downed:UpdatePosition()
	if not self._asset then
		return
	end

	local humanoid = self.Instance:WaitForChild("Humanoid")

	if humanoid.Health > 0 then
		humanoid.Health = -math.huge
	end

	local airship = Knit.GetService("AirshipService"):GetPrimaryAirship()
	local pivot = airship:GetPivot()

	self._asset.MetalFrame.AlignPosition.Position = (pivot * CFrame.new(self._offset)).Position
end

return Downed
