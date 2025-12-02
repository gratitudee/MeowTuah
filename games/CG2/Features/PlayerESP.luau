local Services, Utility, ESP =
	LoadModule("core/Services.lua"), LoadModule("core/Utility.lua"), LoadModule("modules/PlayerESP.lua")
local Players = Services.Players
local Workspace = Services.Workspace
local RunService = Services.RunService

local Player = Utility.GetPlayer()
local Heartbeat = Utility.index(RunService, "Heartbeat")
local PlayerAdded, PlayerRemoving = Utility.index(Players, "PlayerAdded"), Utility.index(Players, "PlayerRemoving")
local FindFirstChild = Utility.FindFirstChild
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

local function GetChildrenWithValidation(Object, Validation)
	local ToReturn = {}
	for _, Child in pairs(GetChildren(Object)) do
		local ShouldPass = true
		if Validation then
			ShouldPass = Validation(Object)
		end

		if ShouldPass then
			table.insert(ToReturn, Object)
		end
	end
	return ToReturn
end

local function WorldToScreen(World)
	local Screen, InBounds = WorldToViewportPoint(Camera, World)
	return Vector2.new(Screen.X, Screen.Y), InBounds, Screen.Z
end

function PlayerESP:DrawThread()
	if not PlayerESP.Enabled then
		for _, Dict in pairs(PlayerESP.Data) do
			for _, drawing in pairs(Dict.Drawings) do
				drawing:SetVisible(false)
			end
		end
		return
	end

	for _, Dictionary in pairs(PlayerESP.Data) do
		local Player = Dictionary.Player
		local Character = Dictionary.Character
		if not Character then
			for _, Dict in pairs(PlayerESP.Data) do
				for _, drawing in pairs(Dict.Drawings) do
					drawing:SetVisible(false)
				end
			end
			continue
		end

		local RootPart = FindFirstChild(Character, "HumanoidRootPart")
		if not RootPart then
			for _, Dict in pairs(PlayerESP.Data) do
				for _, drawing in pairs(Dict.Drawings) do
					drawing:SetVisible(false)
				end
			end
			continue
		end

		local _, OnScreen = WorldToScreen(RootPart.Position)
		if not OnScreen then
			for _, Dict in pairs(PlayerESP.Data) do
				for _, drawing in pairs(Dict.Drawings) do
					drawing:SetVisible(false)
				end
			end
			continue
		end

		local Drawings = Dictionary.Drawings
		local Bounds = ESP:GetBoundingBox(GetChildrenWithValidation(Character, function(object)
			PlayerESP:ValidatePart(object)
		end))
		if not Bounds then
			for _, Dict in pairs(PlayerESP.Data) do
				for _, drawing in pairs(Dict.Drawings) do
					drawing:SetVisible(false)
				end
			end
			continue
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
			local Y = Bounds.Y - TextBounds.Y - 2
			Drawings.Name:SetPosition(X, Y)
			Drawings.Name:SetColor(PlayerESP.Name.Color, PlayerESP.Name.Transparency)
		else
			Drawings.Name:SetVisible(false)
		end
	end
end

function PlayerESP:ValidatePart(Part)
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

	PlayerDict.Character = Player.Character
	PlayerDict.Connections.CharacterAdded = Player.CharacterAdded:Connect(function(Character)
		PlayerDict.Character = Character
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

	local Heartbeat = Heartbeat:Connect(function()
		PlayerESP:DrawThread()
	end)

	table.insert(PlayerESP.ScriptConnections, Added)
	table.insert(PlayerESP.ScriptConnections, Removing)
	table.insert(PlayerESP.ScriptConnections, Heartbeat)
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
