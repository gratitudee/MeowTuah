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

			print(Hitbox)

			local TouchInterest = FindFirstChild(Hitbox, "TouchInterest")
			if TouchInterest and self.Bodypart then
				print("fiad")
				firetouchinterest(TouchInterest, self.Bodypart, true)
				firetouchinterest(TouchInterest, self.Bodypart, false)
			else
				print(TouchInterest)
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
	--[[
	local UpdateRebirth = game:GetService("ReplicatedStorage").RemoteEvents.UpdateRebirthFrame
	for _, Connection in getconnections(UpdateRebirth.OnClientEvent) do
		local old
		old = hookfunction(Connection.Function, function(...)
			if Automation.Flags.AutoRebirth then
				local Args = { ... }
				if Args and Args.CanRebirth == true and Args.IsAtMaxRebirth ~= true then
					-- rebirth.
				end
			end

			return old(...)
		end)
	end]]
	--
end
function Automation.AutoRebirth:Stop() end

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
					print(HighestName)
				end
			end

			return old(...)
		end)
	end
end

function Automation.AutoTycoonManager:Stop()
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
