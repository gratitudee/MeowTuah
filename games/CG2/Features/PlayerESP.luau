local Services, Utility, ESP =
	LoadModule("core/Services.lua"), LoadModule("core/Utility.lua"), LoadModule("modules/PlayerESP.lua")
local Players = Services.Players
local Workspace = Services.Workspace
local RunService = Services.RunService

local LocalPlayer = Utility.GetPlayer()
local RenderStepped = Utility.index(RunService, "RenderStepped")
local PlayerAdded, PlayerRemoving = Utility.index(Players, "PlayerAdded"), Utility.index(Players, "PlayerRemoving")
local FindFirstChild = Utility.FindFirstChild
local FindFirstChildWhichIsA = Utility.FindFirstChildWhichIsA
local GetChildren = Utility.GetChildren
local Camera = Utility.index(Workspace, "CurrentCamera")
local WorldToViewportPoint = Utility.index(Camera, "WorldToViewportPoint")

local PlayerESP = {
	Enabled = false,
	AliveCheck = false,

	ScriptConnections = {},
	Data = {},
	Font = "UI",
	Size = 18,
	MaxDistance = 250,
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

local DrawingFonts = {
	UI = 0,
	System = 1,
	Plex = 2,
	Monospace = 3,
}

local function GetFont(Name)
	return DrawingFonts[Name]
end

local function GetValidParts(Object)
	local validParts = {}

	for _, child in pairs(GetChildren(Object)) do
		if PlayerESP:ValidatePart(child) then
			table.insert(validParts, child)
		end
	end

	return validParts
end

local function WorldToScreen(World)
	local Screen, InBounds = WorldToViewportPoint(Camera, World)
	return Vector2.new(Screen.X, Screen.Y), InBounds, Screen.Z
end

function PlayerESP:DrawPlayer(Dictionary)
	local Player = Dictionary.Player
	local Character = Dictionary.Character
	local Drawings = Dictionary.Drawings
	local Bodyparts = Dictionary.Bodyparts

	if not Character then
		for _, drawing in pairs(Drawings) do
			drawing:SetVisible(false)
		end
		return
	end

	local RootPart = FindFirstChild(Character, "HumanoidRootPart")
	if not RootPart then
		for _, drawing in pairs(Drawings) do
			drawing:SetVisible(false)
		end
		return
	end

	local Distance = "[???m]"
	local LocalPlayerCharacter = Utility.GetCharacter(LocalPlayer)
	local HumanoidRootPart = LocalPlayerCharacter and FindFirstChild(LocalPlayerCharacter, "HumanoidRootPart") or nil
	if HumanoidRootPart then
		local DistanceNumber = (HumanoidRootPart.Position - RootPart.Position).Magnitude
		Distance = `[{tostring(math.floor(DistanceNumber))}m]`
	end

	local _, OnScreen = WorldToScreen(RootPart.Position)
	if not OnScreen then
		for _, drawing in pairs(Drawings) do
			drawing:SetVisible(false)
		end
		return
	end

	local Bounds = ESP:GetBoundingBox(Bodyparts)
	if not Bounds then
		for _, drawing in pairs(Drawings) do
			drawing:SetVisible(false)
		end
		return
	end

	if PlayerESP.Box.Enabled then
		Drawings.Box:SetPosition(Bounds.X, Bounds.Y, Bounds.W, Bounds.H)
		Drawings.Box:SetColor(PlayerESP.Box.Color, PlayerESP.Box.Transparency)
	else
		Drawings.Box:SetVisible(false)
	end

	if PlayerESP["Filled Box"].Enabled then
		Drawings["Filled Box"]:SetPosition(Bounds.X, Bounds.Y, Bounds.W, Bounds.H)
		Drawings["Filled Box"]:SetColor(PlayerESP["Filled Box"].Color, PlayerESP["Filled Box"].Transparency)
	else
		Drawings["Filled Box"]:SetVisible(false)
	end

	if PlayerESP.Name.Enabled then
		Drawings.Name:SetText(Player.Name)
		Drawings.Name.Text.Font = GetFont(PlayerESP.Font)
		Drawings.Name.Text.Size = PlayerESP.Size

		local TextBounds = Drawings.Name.Text.TextBounds
		local X = Bounds.X + (Bounds.W / 2) - (TextBounds.X / 2)
		local Y = Bounds.Y - TextBounds.Y
		Drawings.Name:SetPosition(X, Y)
		Drawings.Name:SetColor(PlayerESP.Name.Color, PlayerESP.Name.Transparency)
	else
		Drawings.Name:SetVisible(false)
	end

	local BottomY = Bounds.Y + Bounds.H
	if PlayerESP.Distance.Enabled then
		Drawings.Distance:SetText(Distance)
		Drawings.Distance.Text.Font = GetFont(PlayerESP.Font)
		Drawings.Distance.Text.Size = PlayerESP.Size

		local TextBounds = Drawings.Distance.Text.TextBounds
		local X = Bounds.X + (Bounds.W / 2) - (TextBounds.X / 2)
		local Y = BottomY

		Drawings.Distance:SetPosition(X, Y)
		Drawings.Distance:SetColor(PlayerESP.Distance.Color, PlayerESP.Distance.Transparency)
		Drawings.Distance:SetVisible(true)

		BottomY = Y + TextBounds.Y
	else
		Drawings.Distance:SetVisible(false)
	end

	if PlayerESP["Health Text"].Enabled and Dictionary.Humanoid then
		local Health, MaxHealth = math.floor(Dictionary.Humanoid.Health), math.floor(Dictionary.Humanoid.MaxHealth)
		local HealthText = `[{tostring(Health)}/{tostring(MaxHealth)}]`
		Drawings["Health Text"]:SetText(HealthText)
		Drawings["Health Text"].Text.Font = GetFont(PlayerESP.Font)
		Drawings["Health Text"].Text.Size = PlayerESP.Size

		local TextBounds = Drawings["Health Text"].Text.TextBounds
		local X = Bounds.X + (Bounds.W / 2) - (TextBounds.X / 2)
		local Y = BottomY

		Drawings["Health Text"]:SetPosition(X, Y)
		Drawings["Health Text"]:SetColor(PlayerESP["Health Text"].Color, PlayerESP["Health Text"].Transparency)
		Drawings["Health Text"]:SetVisible(true)
	else
		Drawings["Health Text"]:SetVisible(false)
	end

	if PlayerESP.Chams.Enabled and Dictionary.Character then
		local ChamsFlags = PlayerESP.Chams
		Drawings.Chams:SetFillProperties(ChamsFlags.Fill.Color, ChamsFlags.Fill.Transparency)
		Drawings.Chams:SetOutlineProperties(ChamsFlags.Outline.Color, ChamsFlags.Outline.Transparency)
		Drawings.Chams:SetCharacter(Dictionary.Character)
		Drawings.Chams:SetVisible(true)
	else
		Drawings.Chams:SetVisible(false)
		Drawings.Chams:SetCharacter(nil)
	end
end

function PlayerESP:ValidatePart(Part)
	if not Part then
		return false
	end

	if typeof(Part) ~= "Instance" then
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

function PlayerESP:InitPlayer(Player)
	PlayerESP.Data[Player.Name] = {
		Player = Player,
		Character = nil,
		Humanoid = nil,
		Bodyparts = {},
		Connections = {},
		Drawings = {},
	}

	local PlayerDict = PlayerESP.Data[Player.Name]

	PlayerDict.Drawings.Box = ESP:DrawBox()
	PlayerDict.Drawings["Filled Box"] = ESP:DrawBoxFilled()
	PlayerDict.Drawings.Name = ESP:DrawText()
	PlayerDict.Drawings.Distance = ESP:DrawText()
	PlayerDict.Drawings["Health Text"] = ESP:DrawText()
	PlayerDict.Drawings.Chams = ESP:DrawHighlight()

	PlayerDict.Character = Player.Character
	PlayerDict.Bodyparts = PlayerDict.Character and GetValidParts(PlayerDict.Character) or {}
	PlayerDict.Humanoid = PlayerDict.Character and FindFirstChildWhichIsA(PlayerDict.Character, "Humanoid", false)
	PlayerDict.Connections.CharacterAdded = Player.CharacterAdded:Connect(function(Character)
		task.wait(1)
		PlayerDict.Character = Character
		PlayerDict.Humanoid = PlayerDict.Character and FindFirstChildWhichIsA(PlayerDict.Character, "Humanoid", false)
		PlayerDict.Bodyparts = GetValidParts(Character)

		PlayerDict.Connections.ChildAdded = Character.ChildAdded:Connect(function(child)
			if PlayerESP:ValidatePart(child) then
				table.insert(PlayerDict.Bodyparts, child)
			end
		end)

		PlayerDict.Connections.ChildRemoving = Character.ChildRemoved:Connect(function(child)
			for i, part in ipairs(PlayerDict.Bodyparts) do
				if part == child then
					table.remove(PlayerDict.Bodyparts, i)
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
		PlayerESP:InitPlayer(Player)
	end

	local Added = PlayerAdded:Connect(function(Player)
		PlayerESP:InitPlayer(Player)
	end)

	local Removing = PlayerRemoving:Connect(function(Player)
		local PlayerDict = PlayerESP.Data[Player.Name]

		for _, connection in pairs(PlayerDict.Connections) do
			connection:Disconnect()
			connection = nil
		end

		for _, drawing in pairs(PlayerDict.Drawings) do
			drawing:Remove()
		end

		PlayerESP.Data[Player.Name] = nil
	end)

	local Info = {
		List = {},
		Index = 1,
		PerFrame = 15,
		LastUpdate = 0,
		UpdatePer = 0,
	}

	local RenderSteppedConnection = RenderStepped:Connect(function()
		local Now = tick()
		if Now - Info.LastUpdate < Info.UpdatePer then
			return
		end
		Info.LastUpdate = Now

		if not PlayerESP.Enabled then
			for _, Dict in pairs(PlayerESP.Data) do
				for _, drawing in pairs(Dict.Drawings) do
					drawing:SetVisible(false)
				end
			end
			return
		end

		if #Info.List == 0 or Info.Index > #Info.List then
			Info.List = {}
			for _, dict in pairs(PlayerESP.Data) do
				if dict.Player.Name == LocalPlayer.Name then
					continue
				end

				table.insert(Info.List, dict)
			end
			Info.Index = 1
		end

		local Processed = 0
		while Processed < Info.PerFrame and Info.Index <= #Info.List do
			MeowTuah:SafeCall(`ESP:DrawPlayer`, PlayerESP:DrawPlayer(Info.List[Info.Index]))
			Info.Index += 1
			Processed += 1
		end
	end)

	table.insert(PlayerESP.ScriptConnections, Added)
	table.insert(PlayerESP.ScriptConnections, Removing)
	table.insert(PlayerESP.ScriptConnections, RenderSteppedConnection)
end

function PlayerESP:Stop()
	for Index, PlayerDict in pairs(PlayerESP.Data) do
		for _, Connection in pairs(PlayerDict.Connections) do
			Connection:Disconnect()
			Connection = nil
		end

		for _, Drawing in pairs(PlayerDict.Drawings) do
			Drawing:Remove()
			Drawing = nil
		end

		PlayerESP.Data[Index] = nil
	end

	for _, ScriptConnection in pairs(PlayerESP.ScriptConnections) do
		ScriptConnection:Disconnect()
		ScriptConnection = nil
	end
end

return PlayerESP
