local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Airship = require(script.Parent.Airship)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

const MAIN_ON_COLOR = Color3.fromRGB(255, 138, 80)
const MAIN_OFF_COLOR = Color3.fromRGB(80, 42, 255)
const GLASS_ON_COLOR = Color3.fromRGB(165, 36, 36)
const GLASS_OFF_COLOR = Color3.fromRGB(50, 11, 11)

const OnBoardAlarm = Component.new({ Tag = "OnBoardAlarm", Extensions = { TroveAdder } })

function OnBoardAlarm:Construct()
	self._scope = Fusion.scoped({
		Observer = Fusion.Observer,
	})
end

function OnBoardAlarm:Start()
	self:SetOff()
	
	local primaryAirship = Knit.GetService("AirshipService"):GetPrimaryAirship()

	Airship:WaitForInstance(primaryAirship):andThen(function(airship)
		local activeThread

		self._trove:Add(self._scope:Observer(airship.EnemyOnBoard):onChange(function()
			local isOn = Fusion.peek(airship.EnemyOnBoard)

			if isOn then
				if activeThread then
					return
				end

				activeThread = self._trove:Add(task.spawn(function()
					while true do
						self:SetOn()
						task.wait(1)
						self:SetOff()
						task.wait(1)
					end
				end))
			else
				if activeThread then
					task.cancel(activeThread)
				end

				self:SetOff()
			end
		end))
	end)
end

function OnBoardAlarm:SetOn()
	self.Instance.AlarmSpinningElement.Color = MAIN_ON_COLOR
	self.Instance.AlarmSpinningElement.Material = Enum.Material.Neon
	self.Instance.Glass.Color = GLASS_ON_COLOR

	for _, v in self.Instance:GetDescendants() do
		if not v:IsA("Light") then
			continue
		end

		v.Enabled = true
	end
end

function OnBoardAlarm:SetOff()
	self.Instance.AlarmSpinningElement.Color = MAIN_OFF_COLOR
	self.Instance.AlarmSpinningElement.Material = Enum.Material.Glass
	self.Instance.Glass.Color = GLASS_OFF_COLOR

	for _, v in self.Instance:GetDescendants() do
		if not v:IsA("Light") then
			continue
		end

		v.Enabled = false
	end
end

function OnBoardAlarm:Stop()
	Fusion.doCleanup(self._scope)
end

return OnBoardAlarm
