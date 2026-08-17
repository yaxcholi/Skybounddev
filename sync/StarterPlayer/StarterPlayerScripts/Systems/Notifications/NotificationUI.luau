local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local TroveAdder = require(ReplicatedStorage.ComponentExtensions.TroveAdder)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local NotificationUI = Component.new({ Tag = "NotificationUI", Extensions = { TroveAdder } })

function NotificationUI:Construct()
	self._scope = Fusion.scoped({
		Hydrate = Fusion.Hydrate,
	})
end

function NotificationUI:Start()
	self._trove:Add(Knit.GetService("NotifyService").Notify:Connect(function(message: string)
		self:Notify(message)
	end))

	self._trove:Add(Knit.GetService("NotifyService").Error:Connect(function(message: string)
		self:Error(message)
	end))

	self._trove:Add(Knit.GetController("NotificationsController").OnNotify:Connect(function(message: string)
		self:Notify(message)
	end))

	self._trove:Add(Knit.GetController("NotificationsController").OnError:Connect(function(message: string)
		self:Error(message)
	end))
end

function NotificationUI:Notify(message: string)
	local template = self._scope:Hydrate(self.Instance.Frame.Template:Clone())({
		Text = message,
		Visible = true,
		Parent = self.Instance.Frame,
	})

	task.delay(3, function()
		template:Destroy()
	end)
end

function NotificationUI:Error(message: string)
	local template = self._scope:Hydrate(self.Instance.Frame.Template:Clone())({
		Text = message,
		Visible = true,
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		Parent = self.Instance.Frame,
	})

	task.delay(3, function()
		template:Destroy()
	end)
end

function NotificationUI:Stop()
	Fusion.doCleanup(self._scope)
end

return NotificationUI
