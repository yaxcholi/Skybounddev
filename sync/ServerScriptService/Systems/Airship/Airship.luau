local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Knit = require(ReplicatedStorage.Packages.Knit)

local MaxHp = 500
local ForwardSpeed = 60
local MaxSteerAngle = 25
local SteerReturnRate = 2
local TickRate = 0.05
local DockTriggerZ = 80
local DockTriggerX = 200
local DockHoverHeight = 25
local DockDuration = 30
local WheelMaxRotation = 90
local LeverMaxAngle = 45

local Airship = Component.new({ Tag = "PrimaryAirship", Extensions = { TroveAdder, RemoteComponent } })

Airship.Client = {
	Hp = Knit.CreateProperty(MaxHp),
	State = Knit.CreateProperty("Moving"),
	AdjustAltitude = Knit.CreateSignal(),
}

function Airship:Construct()
	self._scope = Fusion.scoped({
		Value = Fusion.Value,
	})

	self.EnemyOnBoard = self._scope:Value(false)
	self._hp = MaxHp
	self._steerAngle = 0
	self._state = "Moving"
	self._dockPlatform = nil
	self._seat = nil
	self._steerMotor = nil
	self._leverMotor = nil
	self._wheelBaseC0 = nil
	self._leverBaseC0 = nil
	self._currentVelocity = Vector3.zero
	self._propMotors = {}
	self._propAngle = 0
	self._dockCooldown = false
	self._targetY = nil
end

function Airship:Start()
	local Cylinder004 = self.Instance.BlimpSteeringWheel.Model["Cylinder.004"]
	local LeverMoving = self.Instance.AirshipSpeedLever.LeverMoving
	CollectionService:AddTag(Cylinder004, "WeldIgnore")
	CollectionService:AddTag(LeverMoving, "WeldIgnore")

	for _, V in self.Instance:GetDescendants() do
		if V.Name == "Circle.008" then
			CollectionService:AddTag(V, "WeldIgnore")
		end
	end

	self:Weld()
	self:SetupAnimatedParts(Cylinder004, LeverMoving)
	self:SetupPropellers()

	self._seat = self.Instance:WaitForChild("AirshipSeat")
	self._targetY = self.Instance.PrimaryPart.Position.Y

	self.Client.AdjustAltitude:Connect(function(_, Direction)
		if self._state ~= "Moving" then
			return
		end
		self._targetY = math.clamp(self._targetY + Direction * 25, 30, 300)
	end)

	local PlayerZone = self.Instance:WaitForChild("PlayerZone") :: BasePart

	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include

	self._trove:Add(Timer.Simple(0.2, function()
		local Filter = {}

		for _, Ai in CollectionService:GetTagged("EnemyAI") do
			local Humanoid = Ai:WaitForChild("Humanoid")
			if Humanoid.Health > 0 then
				table.insert(Filter, Ai)
			end
		end

		Params.FilterDescendantsInstances = Filter

		local EnemyOnBoard = #workspace:GetPartsInPart(PlayerZone, Params) > 0

		if Fusion.peek(self.EnemyOnBoard) ~= EnemyOnBoard then
			self.EnemyOnBoard:set(EnemyOnBoard)
		end
	end))

	self._trove:Add(Timer.Simple(TickRate, function()
		self:Tick()
	end))
end

function Airship:SetupPropellers()
	for _, V in self.Instance:GetDescendants() do
		if V.Name ~= "Circle.008" then
			continue
		end
		local Base = nil
		for _, S in V.Parent:GetChildren() do
			if S ~= V and S:IsA("BasePart") then
				Base = S
				break
			end
		end
		if not Base then
			continue
		end
		local Motor = Instance.new("Motor6D")
		Motor.Part0 = Base
		Motor.Part1 = V
		Motor.C0 = Base.CFrame:Inverse() * V.CFrame
		Motor.C1 = CFrame.identity
		Motor.Parent = Base
		table.insert(self._propMotors, { Motor = Motor, BaseC0 = Motor.C0 })
		self._trove:Add(Motor)
	end
end

function Airship:SetupAnimatedParts(Cylinder004, LeverMoving)
	local WheelBase = self.Instance.BlimpSteeringWheel["Cylinder.006"]
	local LeverBase = self.Instance.AirshipSpeedLever.FoundationStatic

	local SteerMotor = Instance.new("Motor6D")
	SteerMotor.Part0 = WheelBase
	SteerMotor.Part1 = Cylinder004
	SteerMotor.C0 = WheelBase.CFrame:Inverse() * Cylinder004.CFrame
	SteerMotor.C1 = CFrame.identity
	SteerMotor.Parent = WheelBase
	self._steerMotor = SteerMotor
	self._wheelBaseC0 = SteerMotor.C0
	self._trove:Add(SteerMotor)

	local LeverMotor = Instance.new("Motor6D")
	LeverMotor.Part0 = LeverBase
	LeverMotor.Part1 = LeverMoving
	LeverMotor.C0 = LeverBase.CFrame:Inverse() * LeverMoving.CFrame
	LeverMotor.C1 = CFrame.identity
	LeverMotor.Parent = LeverBase
	self._leverMotor = LeverMotor
	self._leverBaseC0 = LeverMotor.C0
	self._trove:Add(LeverMotor)
end

function Airship:Tick()
	local PrimaryPart = self.Instance.PrimaryPart
	local CurrentPos = PrimaryPart.Position
	local Seat = self._seat

	if self._state == "Moving" then
		if Seat.Occupant == nil then
			self._currentVelocity = self._currentVelocity:Lerp(Vector3.zero, TickRate * 3)
			PrimaryPart.LinearVelocity.VectorVelocity = self._currentVelocity
			self._steerAngle = self._steerAngle * (1 - SteerReturnRate * TickRate)
			self:AnimateControls(0, 0)
			return
		end

		local ThrottleFloat = Seat.ThrottleFloat
		local SteerFloat = Seat.SteerFloat

		if SteerFloat ~= 0 then
			self._steerAngle = math.clamp(
				self._steerAngle + SteerFloat * MaxSteerAngle * SteerReturnRate * TickRate,
				-MaxSteerAngle,
				MaxSteerAngle
			)
		else
			self._steerAngle = self._steerAngle * (1 - SteerReturnRate * TickRate)
		end

		local Rad = math.rad(self._steerAngle)
		local ForwardDir = Vector3.new(math.sin(Rad), 0, -math.cos(Rad))

		local TargetHorizontal = ForwardDir * (ThrottleFloat * ForwardSpeed)
		local YDiff = (self._targetY - CurrentPos.Y)
		local YVelocity = math.clamp(YDiff * 3, -30, 30)
		local TargetVelocity = Vector3.new(TargetHorizontal.X, YVelocity, TargetHorizontal.Z)
		self._currentVelocity = self._currentVelocity:Lerp(TargetVelocity, TickRate * 5)
		PrimaryPart.LinearVelocity.VectorVelocity = self._currentVelocity
		PrimaryPart.AlignOrientation.CFrame = CFrame.lookAt(CurrentPos, CurrentPos + ForwardDir)

		self:AnimateControls(ThrottleFloat, SteerFloat)
		self:CheckDock(CurrentPos)

	elseif self._state == "Docked" and self._dockPlatform then
		local DockPos = self._dockPlatform:GetPivot().Position
		local HoverPos = Vector3.new(DockPos.X, DockPos.Y + DockHoverHeight, DockPos.Z)
		local Diff = HoverPos - CurrentPos
		local Dist = Diff.Magnitude

		if Dist > 3 then
			PrimaryPart.LinearVelocity.VectorVelocity = Diff.Unit * math.min(ForwardSpeed * 0.5, Dist * 3)
		else
			PrimaryPart.LinearVelocity.VectorVelocity = Vector3.zero
		end

		PrimaryPart.AlignOrientation.CFrame = CFrame.lookAt(CurrentPos, CurrentPos + Vector3.new(0, 0, -1))
		self:AnimateControls(0, 0)
	end
end

function Airship:AnimateControls(ThrottleFloat, SteerFloat)
	if self._steerMotor then
		self._steerMotor.C0 = self._wheelBaseC0
			* CFrame.Angles(0, math.rad(self._steerAngle / MaxSteerAngle * WheelMaxRotation), 0)
	end

	if self._leverMotor then
		self._leverMotor.C0 = self._leverBaseC0
			* CFrame.Angles(0, 0, math.rad(ThrottleFloat * LeverMaxAngle))
	end

	local Speed = self._currentVelocity.Magnitude
	self._propAngle = self._propAngle + (Speed / ForwardSpeed) * 15
	for _, Entry in self._propMotors do
		Entry.Motor.C0 = Entry.BaseC0 * CFrame.Angles(0, 0, math.rad(self._propAngle))
	end
end

function Airship:CheckDock(CurrentPos)
	if self._dockCooldown then
		return
	end
	for _, Platform in CollectionService:GetTagged("DockPlatform") do
		local PlatformPos = Platform:IsA("Model") and Platform:GetPivot().Position or Platform.Position
		local Diff = PlatformPos - CurrentPos
		if math.abs(Diff.Z) < DockTriggerZ and math.abs(Diff.X) < DockTriggerX then
			self:EnterDocked(Platform)
			return
		end
	end
end

function Airship:EnterDocked(Platform)
	if self._state == "Docked" then
		return
	end
	self._state = "Docked"
	self._dockPlatform = Platform
	self._steerAngle = 0
	self._seat.Disabled = true
	self.Client.State:Set("Docked")

	local ProcGenConfig = require(game:GetService("ReplicatedStorage").Data.ProcGenConfig)
	local platformZ = Platform:IsA("Model") and Platform:GetPivot().Position.Z or Platform.Position.Z
	local townIndex = 1
	for i, z in ProcGenConfig.TOWN_Z_POSITIONS do
		if math.abs(z - platformZ) < 400 then
			townIndex = i
			break
		end
	end

	local ContractService = Knit.GetService("ContractService")
	ContractService:OnDocked(townIndex, function()
		self:ExitDocked()
	end)
end

function Airship:ExitDocked()
	self._state = "Moving"
	if self._dockPlatform then
		self._dockPlatform:Destroy()
	end
	self._dockPlatform = nil
	self._seat.Disabled = false
	self._dockCooldown = true
	self.Client.State:Set("Moving")
	task.delay(15, function()
		self._dockCooldown = false
	end)
end

function Airship:TakeDamage(Amount)
	self._hp = math.max(0, self._hp - Amount)
	self.Client.Hp:Set(self._hp)
end

function Airship:Weld()
	for _, V in self.Instance:GetDescendants() do
		if not V:IsA("BasePart") then
			continue
		end

		if V:HasTag("WeldIgnore") then
			V.Anchored = false
			continue
		end

		local Wc = Instance.new("WeldConstraint")
		Wc.Part0 = self.Instance.PrimaryPart
		Wc.Part1 = V
		Wc.Parent = V

		V.Anchored = false
	end
end

function Airship:Stop()
	Fusion.doCleanup(self._scope)
end

return Airship