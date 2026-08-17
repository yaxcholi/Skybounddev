local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local NotificationsController = Knit.CreateController { Name = "NotificationsController" }

NotificationsController.OnNotify = Signal.new()
NotificationsController.OnError = Signal.new()


function NotificationsController:KnitStart()
	
end


function NotificationsController:Notify(message: string)
	self.OnNotify:Fire(message)	
end

function NotificationsController:Error(message: string)
	self.OnError:Fire(message)
end


return NotificationsController
