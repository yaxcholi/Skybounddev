local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local RemoteComponent = require(ReplicatedStorage.Packages.RemoteComponent)

local Jetpack = Component.new({ Tag = "Jetpack", Extensions = { TroveAdder, RemoteComponent } })
Jetpack.Client = {}

function Jetpack:Construct()
	self._cogConstraint = self.Instance:FindFirstChild("CogConstraint", true)
end

function Jetpack:Start()
	self:Disable()

	task.wait(0.1)
	for _,v in self.Instance:GetDescendants() do
		if v.Name == "DeleteMe" then
			v:Destroy()
		end
	end
end

function Jetpack:Enable()
	self._cogConstraint.AngularVelocity = 5

	for _, v in self.Instance:GetDescendants() do
		if v.Name == "FireParticle" then
			v.Enabled = true
		end
	end
end

function Jetpack:Disable()
	self._cogConstraint.AngularVelocity = 0

	for _, v in self.Instance:GetDescendants() do
		if v.Name == "FireParticle" then
			v.Enabled = false
		end
	end
end

function Jetpack.Client:Enable(player: Player)
	if player ~= self.Server:GetOwner() then
		return
	end

	self.Server:Enable()
end

function Jetpack.Client:Disable(player: Player)
	if player ~= self.Server:GetOwner() then
		return
	end

	self.Server:Disable()
end

function Jetpack:GetOwner()
	return Players:GetPlayerFromCharacter(self.Instance.Parent)
end

function Jetpack:Stop() end

return Jetpack
