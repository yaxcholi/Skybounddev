local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Interactable = require(ServerScriptService.Systems.Interactions.Interactable)
local LootGen = require(ServerScriptService.Systems.Loot.LootGen)

local HOLD_OFFSET = CFrame.new(0, 0, -4)
local SURFACE_WELD_NAME = "SurfaceWeld"
local SURFACE_RAYCAST_DISTANCE = 50
local LID_OPEN_TWEEN_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local LID_OPEN_OFFSET = CFrame.new(0, 6, 0) * CFrame.Angles(math.rad(-80), 0, 0)
local LID_DESTROY_DELAY = 0.5

local Crate = Component.new({ Tag = "Crate", Extensions = { TroveAdder, RemoteComponent } })
Crate.Client = {
	PickUp = Knit.CreateSignal(),
	Drop = Knit.CreateSignal(),
	Holder = Knit.CreateProperty(nil),
}

local function getHeldCrate(player: Player)
	for _, crate in Crate:GetAll() do
		if crate:GetHolder() == player then
			return crate
		end
	end

	return nil
end

function Crate:Construct()
	self._carryWeld = nil
	self._surfaceWeld = nil
	self._surfaceOffset = nil
	self._surfacePart = nil
	self._placedPivot = nil
	self._holderConnections = nil
	self._raycastParams = RaycastParams.new()
	self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self._raycastParams.FilterDescendantsInstances = { self.Instance }
end

function Crate:GetHolder(): Player?
	return self.Client.Holder:Get()
end

function Crate:WeldToMain()
	local main = self.Instance:WaitForChild("Main") :: BasePart

	for _, descendant in self.Instance:GetDescendants() do
		if not descendant:IsA("BasePart") or descendant == main then
			continue
		end

		if descendant:FindFirstChildWhichIsA("WeldConstraint") then
			continue
		end

		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Part0 = main
		weldConstraint.Part1 = descendant
		weldConstraint.Parent = descendant
		self._trove:Add(weldConstraint)
	end
end

function Crate:SetAnchored(anchored: boolean)
	for _, descendant in self.Instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
		end
	end
end

function Crate:DestroySurfaceWeld()
	local main = self.Instance:FindFirstChild("Main") :: BasePart?
	if main then
		local existing = main:FindFirstChild(SURFACE_WELD_NAME)
		if existing then
			existing:Destroy()
		end
	end

	self._surfaceWeld = nil
end

function Crate:GetHalfExtentAlongAxis(part: BasePart, axis: Vector3): number
	local up = axis.Unit
	return math.abs(part.CFrame.UpVector:Dot(up)) * part.Size.Y / 2
		+ math.abs(part.CFrame.RightVector:Dot(up)) * part.Size.X / 2
		+ math.abs(part.CFrame.LookVector:Dot(up)) * part.Size.Z / 2
end

function Crate:FindSurfaceBelow(): RaycastResult?
	self._raycastParams.FilterDescendantsInstances = { self.Instance }

	local boundingCFrame, boundingSize = self.Instance:GetBoundingBox()
	local up = boundingCFrame.UpVector
	local bottomPoint = boundingCFrame.Position - up * (boundingSize.Y / 2)

	local result = workspace:Raycast(bottomPoint + up * 0.25, -up * SURFACE_RAYCAST_DISTANCE, self._raycastParams)
	if result and result.Instance:IsA("BasePart") then
		return result
	end

	return workspace:Raycast(bottomPoint + Vector3.new(0, 2, 0), Vector3.new(0, -SURFACE_RAYCAST_DISTANCE, 0), self._raycastParams)
end

function Crate:AlignToSurface(main: BasePart, hitPosition: Vector3, normal: Vector3, referencePivot: CFrame?)
	local up = normal.Unit
	local pivot = referencePivot or self.Instance:GetPivot()
	local forward = pivot.LookVector
	local projectedForward = forward - forward:Dot(up) * up

	if projectedForward.Magnitude < 0.01 then
		projectedForward = Vector3.new(1, 0, 0) - Vector3.new(1, 0, 0):Dot(up) * up
	end
	projectedForward = projectedForward.Unit

	local mainCenter = hitPosition + up * (self:GetHalfExtentAlongAxis(main, up) + 0.01)
	local targetMainCFrame = CFrame.lookAt(mainCenter, mainCenter + projectedForward, up)
	local pivotToMain = pivot:ToObjectSpace(main.CFrame)

	self.Instance:PivotTo(targetMainCFrame * pivotToMain:Inverse())
end

function Crate:WeldToSurface(preservePlacement: boolean?): boolean
	self:DestroySurfaceWeld()

	local main = self.Instance:FindFirstChild("Main") :: BasePart?
	if not main or self:GetHolder() then
		return false
	end

	local result = self:FindSurfaceBelow()
	if not result or not result.Instance:IsA("BasePart") then
		return false
	end

	self:SetAnchored(true)

	if preservePlacement and self._surfaceOffset and self._surfacePart and result.Instance == self._surfacePart then
		main.CFrame = result.Instance.CFrame * self._surfaceOffset
	elseif preservePlacement and self._placedPivot then
		self:AlignToSurface(main, result.Position, result.Normal, self._placedPivot)
	else
		self:AlignToSurface(main, result.Position, result.Normal)
	end

	local surfaceWeld = Instance.new("WeldConstraint")
	surfaceWeld.Name = SURFACE_WELD_NAME
	surfaceWeld.Part0 = result.Instance
	surfaceWeld.Part1 = main
	surfaceWeld.Parent = main
	self._surfaceWeld = surfaceWeld
	self._trove:Add(surfaceWeld)

	self:SetAnchored(false)

	if preservePlacement then
		self._surfaceOffset = nil
		self._surfacePart = nil
		self._placedPivot = nil
	end

	return true
end

function Crate:TryWeldToSurfaceWithRetry()
	for _ = 1, 10 do
		if self:WeldToSurface() then
			return
		end

		task.wait(0.2)
	end
end

function Crate:Start()
	self:WeldToMain()
	self:SetAnchored(true)

	self._trove:Add(task.spawn(function()
		self:TryWeldToSurfaceWithRetry()
	end))

	local interaction = self.Instance:WaitForChild("Interaction")
	interaction:SetAttribute("CustomPrompt", true)

	Interactable:WaitForInstance(interaction):andThen(function(interactable)
		self._interactable = interactable

		self._trove:Add(interactable.OnInteract:Connect(function(player: Player)
			self:OpenDoor(player)
		end))
	end)

	self._trove:Add(self.Client.PickUp:Connect(function(player: Player)
		self:PickUp(player)
	end))

	self._trove:Add(self.Client.Drop:Connect(function(player: Player)
		self:Drop(player)
	end))

	self._trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		if self:GetHolder() == player then
			self:Drop(player)
		end
	end))
end

function Crate:OpenDoor(player: Player)
	if self:GetHolder() or getHeldCrate(player) then
		return
	end

	local door = self.Instance:FindFirstChild("Door") :: MeshPart?
	if not door then
		return
	end

	if self._interactable then
		self._interactable:SetEnabled(false)
	end

	local weld = door:FindFirstChildWhichIsA("WeldConstraint")
	if weld then
		weld:Destroy()
	end
	door.Anchored = true

	local attachment = door:FindFirstChild("LootParticle_Attachment")
	if attachment then
		for _, emitter in attachment:GetChildren() do
			if emitter:IsA("ParticleEmitter") then
				emitter:Emit(25)
			end
		end
	end

	TweenService:Create(door, LID_OPEN_TWEEN_INFO, { CFrame = door.CFrame * LID_OPEN_OFFSET }):Play()

	local lootGen = self.Instance:FindFirstChild("LootGen")
	if lootGen then
		LootGen:WaitForInstance(lootGen):andThen(function(lootComponent)
			lootComponent:Generate()
		end)
	end

	task.delay(LID_DESTROY_DELAY, function()
		if door and door.Parent then
			door:Destroy()
		end
	end)
end

function Crate:PickUp(player: Player)
	if not self.Instance:FindFirstChild("Door") then
		return
	end

	if self:GetHolder() or getHeldCrate(player) then
		return
	end

	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local main = self.Instance:FindFirstChild("Main") :: BasePart?
	if not humanoidRootPart or not main then
		return
	end

	if self._interactable then
		self._interactable:SetEnabled(false)
	end

	self._placedPivot = self.Instance:GetPivot()
	if self._surfaceWeld then
		local surfacePart = self._surfaceWeld.Part0
		if surfacePart then
			self._surfacePart = surfacePart
			self._surfaceOffset = surfacePart.CFrame:ToObjectSpace(main.CFrame)
		end
	end

	self:DestroySurfaceWeld()
	self:SetAnchored(false)

	local holdPosition = (humanoidRootPart.CFrame * HOLD_OFFSET).Position
	main.CFrame = CFrame.new(holdPosition) * main.CFrame.Rotation

	local carryWeld = Instance.new("WeldConstraint")
	carryWeld.Name = "CarryWeld"
	carryWeld.Part0 = humanoidRootPart
	carryWeld.Part1 = main
	carryWeld.Parent = main
	self._carryWeld = carryWeld
	self._trove:Add(carryWeld)

	self.Client.Holder:Set(player)
	self:_trackHolder(character)
end

function Crate:Drop(player: Player)
	if self:GetHolder() ~= player then
		return
	end

	self:_clearHolderTracking()

	if self._carryWeld then
		self._carryWeld:Destroy()
		self._carryWeld = nil
	end

	self.Client.Holder:Set(nil)

	if self._interactable and self.Instance:FindFirstChild("Door") then
		self._interactable:SetEnabled(true)
	end

	self:WeldToSurface(true)
end

function Crate:_trackHolder(character: Model)
	self:_clearHolderTracking()

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	self._holderConnections = self._trove:Extend()
	self._holderConnections:Add(humanoid.Died:Connect(function()
		local holder = self:GetHolder()
		if holder then
			self:Drop(holder)
		end
	end))

	self._holderConnections:Add(character.AncestryChanged:Connect(function(_, parent)
		if parent then
			return
		end

		local holder = self:GetHolder()
		if holder then
			self:Drop(holder)
		end
	end))
end

function Crate:_clearHolderTracking()
	if self._holderConnections then
		self._holderConnections:Destroy()
		self._holderConnections = nil
	end
end

function Crate:Stop()
	self:_clearHolderTracking()
	self:DestroySurfaceWeld()

	if self._carryWeld then
		self._carryWeld = nil
	end
end

return Crate
