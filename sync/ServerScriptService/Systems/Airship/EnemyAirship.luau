local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Timer = require(ReplicatedStorage.Packages.Timer)

local EnemyAirship = Component.new({ Tag = "EnemyAirship", Extensions = { TroveAdder } })

function EnemyAirship:Construct() end

function EnemyAirship:Start()
	self.Instance.PrimaryPart.AlignPosition.Position = self.Instance.PrimaryPart.Position
	self.Instance.PrimaryPart.AlignOrientation.CFrame = self.Instance.PrimaryPart.CFrame

	self._trove:Add(Timer.Simple(0.2, function()
		if self._boarded then
			return
		end

		local airshipService = Knit.GetService("AirshipService")
		local procGenService = Knit.GetService("ProcGenService")
		local primaryAirship = airshipService:GetPrimaryAirship()
		local targetPosition = primaryAirship.PrimaryPart.Position
		local currentPosition = self.Instance.PrimaryPart.Position

		local distance = (currentPosition - targetPosition).Magnitude

		if distance > 1000 then
			return
		end

		if distance < 120 then
			self._boarded = true
			self.Instance.PrimaryPart.AlignPosition.Position = currentPosition

			-- this will cause it to fall
			task.delay(60, function()
				TweenService:Create(self.Instance.PrimaryPart.AlignPosition, TweenInfo.new(10), {
					MaxForce = 0,
				}):Play()

				TweenService:Create(self.Instance.PrimaryPart.AlignOrientation, TweenInfo.new(10), {
					MaxTorque = 0,
					CFrame = CFrame.new(self.Instance.PrimaryPart.Position) * CFrame.Angles(math.pi / 2, 0, 0),
				}):Play()

				-- make sure to kill it if it didnt destroy itself by falling
				task.delay(60, function()
					if self.Instance.Parent then
						self.Instance:Destroy()
					end
				end)
			end)

			return
		end

		local steeringTarget = procGenService:GetSteeringTarget(currentPosition, targetPosition)
		local lookCF = CFrame.lookAt(currentPosition, steeringTarget)

		self.Instance.PrimaryPart.AlignPosition.Position = steeringTarget
		self.Instance.PrimaryPart.AlignOrientation.CFrame = lookCF
	end))
end

function EnemyAirship:Stop() end

return EnemyAirship
