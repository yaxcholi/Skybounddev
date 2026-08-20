local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ContractConfig = require(ReplicatedStorage.Data.ContractConfig)

local ContractService = Knit.CreateService({
	Name = "ContractService",
	Client = {
		Contracts = Knit.CreateProperty({}),
		Phase = Knit.CreateProperty("Hidden"),
		Votes = Knit.CreateProperty({}),
		ActiveContract = Knit.CreateProperty(nil),
		FactionTally = Knit.CreateProperty({ Greed = 0, Fighting = 0, Cowardice = 0 }),
	},
})

function ContractService:KnitInit()
	self._votes = {}
	self._currentContracts = {}
	self._exitCallback = nil
	self._activeModifiers = {}
end

function ContractService:KnitStart()
	self._weatherService = Knit.GetService("WeatherService")
end

function ContractService:OnDocked(townIndex: number, exitCallback: () -> ())
	self._townIndex = townIndex
	self._votes = {}
	if self._weatherService then
		self._weatherService:SetWeather("None")
	end
	self._exitCallback = exitCallback
	self._currentContracts = {}

	for _, faction in ContractConfig.FACTION_ORDER do
		local tier = math.random(townIndex, townIndex + ContractConfig.TIER_CEILING_BONUS)
		local contract = ContractConfig.GetContract(faction, tier)
		table.insert(self._currentContracts, {
			faction = faction,
			tier = tier,
			weather = contract.weather,
			stars = contract.stars,
			dangerStars = contract.dangerStars,
			destination = contract.destination,
			description = contract.description,
			bonus = contract.bonus,
			modifiers = contract.modifiers,
		})
	end

	self.Client.Contracts:Set(self._currentContracts)
	self.Client.Votes:Set({})
	self.Client.Phase:Set("Voting")
end

function ContractService:HandleVote(player: Player, factionName: string)
	if self.Client.Phase:Get() ~= "Voting" then
		return
	end

	local valid = false
	for _, c in self._currentContracts do
		if c.faction == factionName then
			valid = true
			break
		end
	end

	if not valid then
		return
	end

	self._votes[player] = factionName

	local summary = {}
	for p, f in self._votes do
		summary[p.Name] = f
	end
	self.Client.Votes:Set(summary)

	self:_checkMajority()
end

function ContractService:_checkMajority()
	local players = Players:GetPlayers()
	local totalPlayers = #players
	if totalPlayers == 0 then
		return
	end

	local counts = { Greed = 0, Fighting = 0, Cowardice = 0 }
	local totalVotes = 0

	for _, factionName in self._votes do
		if counts[factionName] then
			counts[factionName] += 1
			totalVotes += 1
		end
	end

	local majority = math.ceil(totalPlayers / 2)

	for _, faction in ContractConfig.FACTION_ORDER do
		if counts[faction] >= majority then
			self:_selectContract(faction)
			return
		end
	end

	if totalVotes >= totalPlayers then
		local maxCount = 0
		for _, count in counts do
			if count > maxCount then
				maxCount = count
			end
		end

		local tied = {}
		for faction, count in counts do
			if count == maxCount then
				table.insert(tied, faction)
			end
		end

		self:_selectContract(tied[math.random(1, #tied)])
	end
end

function ContractService:_selectContract(factionName: string)
	local selected = nil
	for _, c in self._currentContracts do
		if c.faction == factionName then
			selected = c
			break
		end
	end

	if not selected then
		return
	end

	self._activeModifiers = selected.modifiers

	if self._weatherService and selected.weather then
		self._weatherService:SetWeather(selected.weather)
	end

	for _, player in Players:GetPlayers() do
		for _, item in selected.bonus do
			local tool = ServerStorage.Assets.Tools:FindFirstChild(item.name)
			if tool then
				for _ = 1, item.quantity do
					tool:Clone().Parent = player.Backpack
				end
			end
		end
	end

	local tally = self.Client.FactionTally:Get()
	self.Client.FactionTally:Set({
		Greed = tally.Greed + (if factionName == "Greed" then 1 else 0),
		Fighting = tally.Fighting + (if factionName == "Fighting" then 1 else 0),
		Cowardice = tally.Cowardice + (if factionName == "Cowardice" then 1 else 0),
	})

	self.Client.ActiveContract:Set(selected)
	self.Client.Phase:Set("Selected")

	if self._exitCallback then
		self._exitCallback()
		self._exitCallback = nil
	end
end

function ContractService:GetModifier(id: string): any
	return self._activeModifiers and self._activeModifiers[id]
end

function ContractService:GetEndingFaction(): string
	local tally = self.Client.FactionTally:Get()
	local max = 0
	local leaders = {}

	for faction, count in tally do
		if count > max then
			max = count
			leaders = { faction }
		elseif count == max and count > 0 then
			table.insert(leaders, faction)
		end
	end

	if #leaders == 1 then
		return leaders[1]
	elseif #leaders == 0 then
		return "None"
	end

	return leaders[math.random(1, #leaders)]
end

function ContractService.Client:VoteContract(player: Player, factionName: string)
	self.Server:HandleVote(player, factionName)
end

return ContractService
