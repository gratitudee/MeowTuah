local Services, Utility = LoadModule("core/Services.lua"), LoadModule("core/Utility.lua")
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local TweenService = Services.TweenService

local Player = Utility.GetPlayer()
local Heartbeat = Utility.index(RunService, "Heartbeat")
local FindFirstChild = Utility.FindFirstChild
local GetChildren = Utility.GetChildren
local FindFirstChildWhichIsA = Utility.FindFirstChildWhichIsA

local Automation = {
	Flags = {
		AutoBuyButtons = false,
		AutoBuyButtonPreferences = {
			["Ignore Tokens"] = true,
			["Low Priority Blue Buttons"] = false,
			["Rapid Buy (Overrides All)"] = false,
		},
		AutoRebirth = false,
		AutoAscend = false,
		AutoTycoonManager = false,
		AutoGetBerry = false,
		AutoGetBerryOptions = {
			["Tween Speed"] = 100,
		},
	},

	AutoBuyButtons = {
		Character = nil,
		Bodypart = nil,
		Connections = {},
		Suffixes = {
			K = 1e3,
			M = 1e6,
			B = 1e9,
			T = 1e12,
			Q = 1e15,
			Qn = 1e18,
			S = 1e21,
			Sp = 1e24,
			Oc = 1e27,
			No = 1e30,
			De = 1e33,
			UDe = 1e36,
			DDe = 1e39,
			TDe = 1e42,
			QDe = 1e45,
			QnDe = 1e48,
		},
		ButtonColours = {
			Blue = Color3.fromRGB(35, 123, 255),
			Token = Color3.fromRGB(139, 87, 202),
		},
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

	AutoGetBerry = {
		Connections = {},
		CurrentTarget = nil,
	},
}

function Automation.AutoGetBerry:Start()
	local Growables = FindFirstChild(workspace, "Growables")

	self.Character = Utility.index(Player, "Character")
	self.Root = FindFirstChild(self.Character, "HumanoidRootPart")
	self.CurrentTarget = nil
	self.ActiveTween = nil

	local function ClearTween()
		if self.ActiveTween then
			self.ActiveTween:Cancel()
			self.ActiveTween = nil
		end
		self.CurrentTarget = nil
	end

	local CharacterAddedConnection = Utility.index(Player, "CharacterAdded"):Connect(function(Character)
		self.Character = Character
		self.Root = FindFirstChild(Character, "HumanoidRootPart")
		ClearTween()
	end)

	local HeartbeatConnection = Heartbeat:Connect(function()
		if not Automation.Flags.AutoGetBerry then
			return
		end

		if not self.Root or not self.Root:IsDescendantOf(workspace) then
			return
		end

		if self.CurrentTarget or self.ActiveTween then
			return
		end

		local Children = GetChildren(Growables)
		if #Children == 0 then
			return
		end

		self.CurrentTarget = Children[1]
		local Target = self.CurrentTarget
		if not Target:IsDescendantOf(workspace) then
			self.CurrentTarget = nil
			return
		end

		local Distance = (self.Root.Position - Target.Position).Magnitude
		local Speed = Automation.Flags.AutoGetBerryOptions["Tween Speed"]
		local Info = TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)

		local Tween = TweenService:Create(self.Root, Info, { CFrame = Target.CFrame })
		self.ActiveTween = Tween
		self.Root.Anchored = true

		local Completed
		Completed = Tween.Completed:Connect(function()
			Completed:Disconnect()
			ClearTween()
			self.Root.Anchored = false
		end)

		Tween:Play()

		task.spawn(function()
			while self.CurrentTarget == Target and Target:IsDescendantOf(workspace) do
				task.wait()
			end

			if self.ActiveTween == Tween then
				ClearTween()
			end

			if Completed.Connected then
				Completed:Disconnect()
			end
		end)
	end)

	table.insert(self.Connections, HeartbeatConnection)
	table.insert(self.Connections, CharacterAddedConnection)
end

function Automation.AutoGetBerry:Stop()
	for _, connection in pairs(self.Connections) do
		connection:Disconnect()
		connection = nil
	end

	if self.ActiveTween then
		self.ActiveTween:Cancel()
		self.ActiveTween = nil
	end
	self.CurrentTarget = nil
end

function Automation.AutoBuyButtons:ParseString(suffix)
	if typeof(suffix) ~= "string" then
		return tonumber(suffix)
	end
	suffix = suffix:gsub("[%$,]", "")

	if suffix:match("Token") then
		local num = suffix:match("([%d%.]+)")
		return tonumber(num) or 0
	end

	local num, suf = suffix:match("([%d%.]+)(%a+)")
	if not num then
		return tonumber(suffix) or 0
	end
	num = tonumber(num)
	local mult = self.Suffixes[suf]
	if not mult then
		return num
	end
	return num * mult
end

function Automation.AutoBuyButtons:GetButtons()
	local Event = ReplicatedStorage.FetchFunctions.FetchButtonModels
	local Buttons, ValidButtons = Event:InvokeServer(), {}
	local Pref = Automation.Flags.AutoBuyButtonPreferences
	local TokenColor = self.ButtonColours.Token

	for _, Button in pairs(Buttons) do
		local InnerButton = Button:FindFirstChild("Button")
		if not InnerButton then
			continue
		end

		local UI = InnerButton:FindFirstChild("UI")
		if not UI then
			continue
		end

		local Price = UI:FindFirstChild("Price")
		if not Price or Price.Text == "" then
			continue
		end

		local Hitbox = Button:FindFirstChild("Hitbox")
		if not Hitbox then
			continue
		end

		local isFree = Price.Text:lower():find("free") ~= nil
		if Pref["Ignore Tokens"] and not isFree then
			local isTokenColor = InnerButton.Color == TokenColor
			local isTokenText = Price.Text:find("Token")

			if isTokenColor or isTokenText then
				continue
			end
		end

		local Cost = isFree and 0 or self:ParseString(Price.Text)

		table.insert(ValidButtons, {
			Instance = Button,
			Color = InnerButton.Color,
			Hitbox = Hitbox,
			Cost = Cost,
			PriceText = Price.Text,
			isFree = isFree,
		})
	end

	if #ValidButtons == 0 then
		return nil
	end

	return ValidButtons
end

function Automation.AutoBuyButtons:ChooseButton(ButtonList)
	local Pref = Automation.Flags.AutoBuyButtonPreferences
	local ColorBlue = self.ButtonColours.Blue

	local nonBlue, blue = {}, {}

	if not ButtonList then
		return nil
	end

	for _, btn in pairs(ButtonList) do
		if btn.isFree then
			return btn
		end
	end

	for _, btn in ipairs(ButtonList) do
		if btn.Color == ColorBlue then
			table.insert(blue, btn)
		else
			table.insert(nonBlue, btn)
		end
	end

	local function cheapest(list)
		table.sort(list, function(a, b)
			return a.Cost < b.Cost
		end)
		return list[1]
	end

	if Pref["Low Priority Blue Buttons"] then
		if #nonBlue > 0 then
			return cheapest(nonBlue)
		end
		if #blue > 0 then
			return cheapest(blue)
		end
		return nil
	end

	return cheapest(ButtonList)
end

function Automation.AutoBuyButtons:Start()
	local PlayerMoneyValue = Player.leaderstats.Money
	local RunConnection = Heartbeat:Connect(function()
		if not Automation.Flags.AutoBuyButtons then
			return
		end

		if not self.Bodypart then
			return
		end

		local Buttons = self:GetButtons()
		local ParsedPlayerMoney = self:ParseString(PlayerMoneyValue.Value)
		if Automation.Flags.AutoBuyButtonPreferences["Rapid Buy (Overrides All)"] then
			for _, button in pairs(Buttons) do
				if ParsedPlayerMoney >= button.Cost then
					firetouchinterest(button.Hitbox, self.Bodypart, true)
					firetouchinterest(button.Hitbox, self.Bodypart, false)
				end
			end
		else
			local ChosenButton = self:ChooseButton(Buttons)
			if ChosenButton and ParsedPlayerMoney >= ChosenButton.Cost then
				firetouchinterest(ChosenButton.Hitbox, self.Bodypart, true)
				firetouchinterest(ChosenButton.Hitbox, self.Bodypart, false)
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
				local Data = Args[1]
				if Args and Data.CanRebirth and not Data.IsAtMaxRebirth then
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
			if Automation.Flags.AutoAscend then
				local Args = { ... }
				local Data = Args[1]
				if Data and Data.CanAscend and Data.IsAtMaxRebirth then
					if Ascend:InvokeServer() then
						MeowTuah.Library:Notify("[AUTO ASCEND] - SUCCESSFULLY ASCENDED!")
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
