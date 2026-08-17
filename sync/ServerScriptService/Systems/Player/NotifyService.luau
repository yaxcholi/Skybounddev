local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local NotifyService = Knit.CreateService({
	Name = "NotifyService",
	Client = {
		Notify = Knit.CreateSignal(),
		Error = Knit.CreateSignal(),
	},
})

function NotifyService:Notify(player: Player, message: string)
	self.Client.Notify:Fire(player, message)
end

function NotifyService:Error(player: Player, message: string)
	self.Client.Error:Fire(player, message)
end

return NotifyService
