local Services, Utility = LoadModule("core/Services.lua"), LoadModule("core/Utility.lua")
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local Player = Utility.GetPlayer()
local Heartbeat = Utility.index(RunService, "Heartbeat")
local FindFirstChild = Utility.FindFirstChild
local FindFirstChildWhichIsA = Utility.FindFirstChildWhichIsA

local Automation = {
	Flags = {
		AutoBuyButtons = false,
		AutoRebirth = false,
		AutoAscend = false,
		AutoTycoonManager = false,
	},

	AutoBuyButtons = {
		Character = nil,
		Bodypart = nil,
		Connections = {},
	},

	AutoRebirth = {
		Connections = {},
	},

	AutoAscend = {
		Connections = {},
	},

	AutoTycoonManager = {
		Hooked = nil,
		Values = {
			BestValue = nil,
		},
		Connections = {},
	},
}

function Automation.AutoBuyButtons:Start()
	local Event = ReplicatedStorage.FetchFunctions.FetchButtonModels

	local RunConnection = Heartbeat:Connect(function()
		if not Automation.Flags.AutoBuyButtons then
			return
		end

		for _, Button in pairs(Event:InvokeServer()) do
			local Hitbox = FindFirstChild(Button, "Hitbox")
			if not Hitbox then
				print("nio")
				continue
			end

			if Hitbox and self.Bodypart then
				firetouchinterest(Hitbox, self.Bodypart, true)
				firetouchinterest(Hitbox, self.Bodypart, false)
			end
		end
	end)

	self.Character = Utility.index(Player, "Character")
	self.Bodypart = FindFirstChildWhichIsA(self.Character, "BasePart", false)

	local Added = Utility.index(Player, "CharacterAdded"):Connect(function(Character)
		self.Character = Character
		self.Bodypart = FindFirstChildWhichIsA(Character, "BasePart", false)
	end)

	table.insert(self.Connections, RunConnection)
	table.insert(self.Connections, Added)
end

function Automation.AutoBuyButtons:Stop()
	for _, connection in pairs(self.Connections) do
		connection:Disconnect()
		connection = nil
	end

	self.Character = nil
	self.Bodypart = nil
end

function Automation.AutoRebirth:Start()
	local UpdateRebirth = ReplicatedStorage.RemoteEvents.UpdateRebirthFrame
	local Rebirth = ReplicatedStorage.RemoteFunctions.Rebirth
	for _, Connection in getconnections(UpdateRebirth.OnClientEvent) do
		local old
		old = hookfunction(Connection.Function, function(...)
			if Automation.Flags.AutoRebirth then
				local Args = { ... }
				if Args and Args.CanRebirth == true and Args.IsAtMaxRebirth ~= true then
					if Rebirth:InvokeServer() then
						MeowTuah.Library:Notify("[AUTO REBIRTH] - SUCCESSFULLY REBIRTHED!")
					end
				end
			end

			return old(...)
		end)
	end
end

function Automation.AutoRebirth:Stop() end

function Automation.AutoAscend:Start()
	local UpdateRebirth = ReplicatedStorage.RemoteEvents.UpdateRebirthFrame
	local Ascend = ReplicatedStorage.RemoteFunctions.Ascend
	for _, Connection in getconnections(UpdateRebirth.OnClientEvent) do
		local old
		old = hookfunction(Connection.Function, function(...)
			if Automation.Flags.AutoRebirth then
				local Args = { ... }
				if Args and Args.CanAscend == true then
					if Ascend:InvokeServer() then
						MeowTuah.Library:Notify("[AUTO ASCEND] - SUCCESSFULLY ASCEND!")
					end
				end
			end

			return old(...)
		end)
	end
end

function Automation.AutoAscend:Stop() end

function Automation.AutoTycoonManager:Start()
	local SelectIndustry = ReplicatedStorage.RemoteEvents.SelectNewIndusty
	local UpdateIndustry = ReplicatedStorage.RemoteEvents.UpdateIndustries
	local Settings = ReplicatedStorage.RemoteFunctions.ApplyNewSetting
	for _, Connection in getconnections(UpdateIndustry.OnClientEvent) do
		local old
		old = hookfunction(Connection.Function, function(...)
			if Automation.Flags.AutoTycoonManager then
				local HighestName, HighestValue = nil, -math.huge
				for name, value in pairs(...) do
					if value > HighestValue then
						HighestValue = value
						HighestName = name
					end
				end

				Settings:InvokeServer("UseManager", HighestValue > 1 and 1 or 0)
				if HighestValue > 1 and self.Values.BestValue ~= HighestName then
					self.Values.BestValue = HighestName
					SelectIndustry:FireServer(HighestName)
				end
			end

			return old(...)
		end)
	end
end

function Automation.AutoTycoonManager:Stop()
	-- unsure how to actually unhook shit yet tbh

	for _, Connection in pairs(self.Connections) do
		Connection:Disconnect()
		Connection = nil
	end
end

function Automation:Start()
	for _, Feature in pairs(Automation) do
		if type(Feature) == "function" then
			continue
		end

		if Feature ~= Automation.Flags then
			Feature:Start()
		end
	end
end

function Automation:Stop()
	for _, Feature in pairs(Automation) do
		if type(Feature) == "function" then
			continue
		end

		if Feature ~= Automation.Flags then
			Feature:Stop()
		end
	end
end

return Automation
