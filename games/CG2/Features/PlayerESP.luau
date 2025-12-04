local Services = LoadModule("core/Services.lua")
local Utility = LoadModule("core/Utility.lua")
local ESP = LoadModule("modules/PlayerESP.lua")

local Players = Services.Players
local Workspace = Services.Workspace
local RunService = Services.RunService

local LocalPlayer = Utility.GetPlayer()
local Camera = Utility.index(Workspace, "CurrentCamera")

local DrawingFonts = {
	UI = 0,
	System = 1,
	Plex = 2,
	Monospace = 3,
}

local DefaultConfig = {
	Enabled = false,
	Font = "UI",
	Size = 18,

	Box = {
		Enabled = false,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
	},

	["Filled Box"] = {
		Enabled = false,
		Color = Color3.new(1, 1, 1),
		Transparency = 0.85,
	},

	Name = {
		Enabled = false,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
	},

	Distance = {
		Enabled = false,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
	},

	["Health Text"] = {
		Enabled = false,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
	},

	Chams = {
		Enabled = false,
		Fill = {
			Color = Color3.new(1, 1, 1),
			Transparency = 0.75,
		},
		Outline = {
			Color = Color3.new(0, 0, 0),
			Transparency = 0,
		},
	},
}

local PlayerESP = setmetatable(DefaultConfig, {})
PlayerESP.ScriptConnections = {}
PlayerESP.Data = {}

local function GetFont(Name)
	return DrawingFonts[Name] or DrawingFonts.UI
end

local function WorldToScreen(WorldPosition)
	local Screen, InBounds = Utility.index(Camera, "WorldToViewportPoint")(Camera, WorldPosition)
	return Vector2.new(Screen.X, Screen.Y), InBounds, Screen.Z
end

local function GetValidParts(Object)
	local ValidParts = {}

	for _, Child in pairs(Utility.GetChildren(Object)) do
		if PlayerESP:ValidatePart(Child) then
			table.insert(ValidParts, Child)
		end
	end

	return ValidParts
end

local function CalculateDistance(RootPart)
	local LocalCharacter = Utility.GetCharacter(LocalPlayer)
	if not LocalCharacter then
		return "[???m]"
	end

	local LocalRoot = Utility.FindFirstChild(LocalCharacter, "HumanoidRootPart")
	if not LocalRoot then
		return "[???m]"
	end

	local Distance = (LocalRoot.Position - RootPart.Position).Magnitude
	return string.format("[%dm]", math.floor(Distance))
end

local function HideAllDrawings(Drawings)
	for _, Drawing in pairs(Drawings) do
		Drawing:SetVisible(false)
	end
end

function PlayerESP:ValidatePart(Part)
	if not Part or typeof(Part) ~= "Instance" then
		return false
	end

	if not Part:IsA("BasePart") then
		return false
	end

	if Part.Transparency >= 1 then
		return false
	end

	return true
end

function PlayerESP:DrawPlayer(Dictionary)
	local Player = Dictionary.Player
	local Character = Dictionary.Character
	local Drawings = Dictionary.Drawings
	local Bodyparts = Dictionary.Bodyparts

	if not Character then
		HideAllDrawings(Drawings)
		return
	end

	local RootPart = Utility.FindFirstChild(Character, "HumanoidRootPart")
	if not RootPart then
		HideAllDrawings(Drawings)
		return
	end

	local _, OnScreen = WorldToScreen(RootPart.Position)
	if not OnScreen then
		HideAllDrawings(Drawings)
		return
	end

	local Bounds = ESP:GetBoundingBox(Bodyparts)
	if not Bounds then
		HideAllDrawings(Drawings)
		return
	end

	if self.Box.Enabled then
		Drawings.Box:SetPosition(Bounds.X, Bounds.Y, Bounds.W, Bounds.H)
		Drawings.Box:SetColor(self.Box.Color, self.Box.Transparency)
	else
		Drawings.Box:SetVisible(false)
	end

	if self["Filled Box"].Enabled then
		Drawings["Filled Box"]:SetPosition(Bounds.X, Bounds.Y, Bounds.W, Bounds.H)
		Drawings["Filled Box"]:SetColor(self["Filled Box"].Color, self["Filled Box"].Transparency)
	else
		Drawings["Filled Box"]:SetVisible(false)
	end

	if self.Name.Enabled then
		Drawings.Name:SetText(Player.Name)
		Drawings.Name.Text.Font = GetFont(self.Font)
		Drawings.Name.Text.Size = self.Size

		local TextBounds = Drawings.Name.Text.TextBounds
		local X = Bounds.X + (Bounds.W / 2) - (TextBounds.X / 2)
		local Y = Bounds.Y - TextBounds.Y

		Drawings.Name:SetPosition(X, Y)
		Drawings.Name:SetColor(self.Name.Color, self.Name.Transparency)
	else
		Drawings.Name:SetVisible(false)
	end

	local BottomY = Bounds.Y + Bounds.H

	if self.Distance.Enabled then
		local Distance = CalculateDistance(RootPart)
		Drawings.Distance:SetText(Distance)
		Drawings.Distance.Text.Font = GetFont(self.Font)
		Drawings.Distance.Text.Size = self.Size

		local TextBounds = Drawings.Distance.Text.TextBounds
		local X = Bounds.X + (Bounds.W / 2) - (TextBounds.X / 2)

		Drawings.Distance:SetPosition(X, BottomY)
		Drawings.Distance:SetColor(self.Distance.Color, self.Distance.Transparency)
		Drawings.Distance:SetVisible(true)

		BottomY = BottomY + TextBounds.Y
	else
		Drawings.Distance:SetVisible(false)
	end

	if self["Health Text"].Enabled and Dictionary.Humanoid then
		local Health = math.floor(Dictionary.Humanoid.Health)
		local MaxHealth = math.floor(Dictionary.Humanoid.MaxHealth)
		local HealthText = string.format("[%d/%d]", Health, MaxHealth)

		Drawings["Health Text"]:SetText(HealthText)
		Drawings["Health Text"].Text.Font = GetFont(self.Font)
		Drawings["Health Text"].Text.Size = self.Size

		local TextBounds = Drawings["Health Text"].Text.TextBounds
		local X = Bounds.X + (Bounds.W / 2) - (TextBounds.X / 2)

		Drawings["Health Text"]:SetPosition(X, BottomY)
		Drawings["Health Text"]:SetColor(self["Health Text"].Color, self["Health Text"].Transparency)
		Drawings["Health Text"]:SetVisible(true)
	else
		Drawings["Health Text"]:SetVisible(false)
	end

	if self.Chams.Enabled and Dictionary.Character then
		Drawings.Chams:SetFillProperties(self.Chams.Fill.Color, self.Chams.Fill.Transparency)
		Drawings.Chams:SetOutlineProperties(self.Chams.Outline.Color, self.Chams.Outline.Transparency)
		Drawings.Chams:SetCharacter(Dictionary.Character)
		Drawings.Chams:SetVisible(true)
	else
		Drawings.Chams:SetVisible(false)
		Drawings.Chams:SetCharacter(nil)
	end
end

function PlayerESP:InitPlayer(Player)
	self.Data[Player.Name] = {
		Player = Player,
		Character = nil,
		Humanoid = nil,
		Bodyparts = {},
		Connections = {},
		Drawings = {},
	}

	local PlayerDict = self.Data[Player.Name]

	PlayerDict.Drawings.Box = ESP:DrawBox()
	PlayerDict.Drawings["Filled Box"] = ESP:DrawBoxFilled()
	PlayerDict.Drawings.Name = ESP:DrawText()
	PlayerDict.Drawings.Distance = ESP:DrawText()
	PlayerDict.Drawings["Health Text"] = ESP:DrawText()
	PlayerDict.Drawings.Chams = ESP:DrawHighlight()

	PlayerDict.Character = Player.Character
	PlayerDict.Bodyparts = PlayerDict.Character and GetValidParts(PlayerDict.Character) or {}
	PlayerDict.Humanoid = PlayerDict.Character
		and Utility.FindFirstChildWhichIsA(PlayerDict.Character, "Humanoid", false)

	PlayerDict.Connections.CharacterAdded = Player.CharacterAdded:Connect(function(Character)
		task.wait(1)

		PlayerDict.Character = Character
		PlayerDict.Humanoid = Utility.FindFirstChildWhichIsA(Character, "Humanoid", false)
		PlayerDict.Bodyparts = GetValidParts(Character)

		PlayerDict.Connections.ChildAdded = Character.ChildAdded:Connect(function(Child)
			if self:ValidatePart(Child) then
				table.insert(PlayerDict.Bodyparts, Child)
			end
		end)

		PlayerDict.Connections.ChildRemoving = Character.ChildRemoved:Connect(function(Child)
			for I, Part in ipairs(PlayerDict.Bodyparts) do
				if Part == Child then
					table.remove(PlayerDict.Bodyparts, I)
					break
				end
			end
		end)
	end)

	PlayerDict.Connections.CharacterRemoved = Player.CharacterRemoving:Connect(function()
		PlayerDict.Character = nil
		PlayerDict.Bodyparts = {}

		if PlayerDict.Connections.ChildAdded then
			PlayerDict.Connections.ChildAdded:Disconnect()
			PlayerDict.Connections.ChildAdded = nil
		end

		if PlayerDict.Connections.ChildRemoving then
			PlayerDict.Connections.ChildRemoving:Disconnect()
			PlayerDict.Connections.ChildRemoving = nil
		end
	end)
end

function PlayerESP:Start()
	for _, Player in pairs(Players:GetPlayers()) do
		self:InitPlayer(Player)
	end

	local PlayerAdded = Utility.index(Players, "PlayerAdded"):Connect(function(Player)
		self:InitPlayer(Player)
	end)

	local PlayerRemoving = Utility.index(Players, "PlayerRemoving"):Connect(function(Player)
		local PlayerDict = self.Data[Player.Name]
		if not PlayerDict then
			return
		end

		for _, Connection in pairs(PlayerDict.Connections) do
			Connection:Disconnect()
		end

		for _, Drawing in pairs(PlayerDict.Drawings) do
			Drawing:Remove()
		end

		self.Data[Player.Name] = nil
	end)

	local RenderInfo = {
		List = {},
		Index = 1,
		PerFrame = 15,
		LastUpdate = 0,
		UpdatePer = 0,
	}

	local RenderConnection = Utility.index(RunService, "RenderStepped"):Connect(function()
		local Now = tick()

		if Now - RenderInfo.LastUpdate < RenderInfo.UpdatePer then
			return
		end
		RenderInfo.LastUpdate = Now

		if not self.Enabled then
			for _, Dict in pairs(self.Data) do
				HideAllDrawings(Dict.Drawings)
			end
			return
		end

		if #RenderInfo.List == 0 or RenderInfo.Index > #RenderInfo.List then
			RenderInfo.List = {}

			for _, Dict in pairs(self.Data) do
				if Dict.Player.Name ~= LocalPlayer.Name then
					table.insert(RenderInfo.List, Dict)
				end
			end

			RenderInfo.Index = 1
		end

		local Processed = 0
		while Processed < RenderInfo.PerFrame and RenderInfo.Index <= #RenderInfo.List do
			MeowTuah:SafeCall("ESP:DrawPlayer", self:DrawPlayer(RenderInfo.List[RenderInfo.Index]))
			RenderInfo.Index = RenderInfo.Index + 1
			Processed = Processed + 1
		end
	end)

	table.insert(self.ScriptConnections, PlayerAdded)
	table.insert(self.ScriptConnections, PlayerRemoving)
	table.insert(self.ScriptConnections, RenderConnection)
end

function PlayerESP:Stop()
	for _, PlayerDict in pairs(self.Data) do
		for _, Connection in pairs(PlayerDict.Connections) do
			Connection:Disconnect()
		end

		for _, Drawing in pairs(PlayerDict.Drawings) do
			Drawing:Remove()
		end
	end

	self.Data = {}

	for _, Connection in pairs(self.ScriptConnections) do
		Connection:Disconnect()
	end

	self.ScriptConnections = {}
end

return PlayerESP
