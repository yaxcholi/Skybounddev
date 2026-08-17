local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ReviveUtil = require(ReplicatedStorage.Utils.ReviveUtil)

local LOW_HEIGHT = -100
local GAME_END_COUNTDOWN = 10
local REVIVE_RANGE = 10

local ReviveService = Knit.CreateService({
	Name = "ReviveService",
	Client = {
		GameEndCountdown = Knit.CreateProperty(nil),
	},
})

function ReviveService:IsCharacterAlive(character: Model): boolean
	if character:HasTag("Dead") or character:HasTag("Downed") then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function ReviveService:IsPlayerDead(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end

	if character:HasTag("Downed") or character:HasTag("Dead") then
		return true
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return not humanoid or humanoid.Health <= 0
end

function ReviveService:AreAllTeamMembersDead(): boolean
	local players = Players:GetPlayers()
	if #players == 0 then
		return false
	end

	for _, player in players do
		if not player.Character then
			return false
		end

		if not self:IsPlayerDead(player) then
			return false
		end
	end

	return true
end

function ReviveService:UpdateGameEndCountdown()
	if not self:AreAllTeamMembersDead() then
		if self.Client.GameEndCountdown:Get() ~= nil then
			self.Client.GameEndCountdown:Set(nil)
		end
		return
	end

	local current = self.Client.GameEndCountdown:Get()
	if current == nil then
		self.Client.GameEndCountdown:Set(GAME_END_COUNTDOWN)
	elseif current > 0 then
		local nextValue = current - 1
		self.Client.GameEndCountdown:Set(nextValue)

		if nextValue == 0 then
			print("Game over: all team members are dead.")
		end
	end
end

function ReviveService:KnitStart()
	Timer.Simple(0.2, function()
		for _, player in Players:GetPlayers() do
			local character = player.Character

			if not character then
				continue
			end

			local position = character:GetPivot().Position

			if position.Y < LOW_HEIGHT then
				character:AddTag("Downed")
			end
		end
	end)

	Timer.Simple(1, function()
		self:UpdateGameEndCountdown()
	end)

	Observers.observeCharacter(function(_, character: Model)
		local trove = Trove.new()

		local humanoid = character:WaitForChild("Humanoid")

		trove:Add(humanoid.Died:Connect(function()
			character:AddTag("Dead")
		end))

		return function()
			trove:Destroy()
		end
	end)
end

function ReviveService:RespawnDeadPlayer(player: Player)
	player:LoadCharacterAsync()

	local character = player.Character or player.CharacterAdded:Wait()

	if not character then
		return
	end

	task.wait(0.2)
	character:AddTag("Downed")
	self:UpdateGameEndCountdown()
end

function ReviveService:TeamRevive(reviver: Player, target: Player)
	if reviver == target then
		return
	end

	local reviverCharacter = reviver.Character
	local targetCharacter = target.Character

	if not reviverCharacter or not targetCharacter then
		return
	end

	if not self:IsCharacterAlive(reviverCharacter) then
		return
	end

	if not ReviveUtil.hasBandageEquipped(reviverCharacter) then
		return
	end

	if not targetCharacter:HasTag("Dead") then
		return
	end

	local reviverRoot = reviverCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not reviverRoot or not targetRoot then
		return
	end

	if (reviverRoot.Position - targetRoot.Position).Magnitude > REVIVE_RANGE then
		return
	end

	targetCharacter:RemoveTag("Dead")
	target:LoadCharacterAsync()
	self:UpdateGameEndCountdown()
end

function ReviveService:SelfRevive(player: Player)
	player:LoadCharacterAsync()
	self:UpdateGameEndCountdown()
end

function ReviveService.Client:SelfRevive(player: Player)
	self.Server:SelfRevive(player)
end

function ReviveService:KnitInit() end

return ReviveService
