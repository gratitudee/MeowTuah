-- References
local Services, Utility = LoadModule("core/Services.lua"), LoadModule("core/Utility.lua")
local Workspace = Services.Workspace
local RunService = Services.RunService

local Player = Utility.GetPlayer()
local Camera = Utility.index(Workspace, "CurrentCamera")
local WorldToViewportPoint = Utility.index(Camera, "WorldToViewportPoint")
local Heartbeat = Utility.index(RunService, "Heartbeat")
local FindFirstChild = Utility.FindFirstChild
local FindFirstChildWhichIsA = Utility.FindFirstChildWhichIsA
local GetChildren = Utility.GetChildren
local Trinkets = FindFirstChild(Workspace, "Trinkets") or FindFirstChild(Workspace, "TrinketSpawns")

local DrawingFonts = {
	UI = 0,
	System = 1,
	Plex = 2,
	Monospace = 3,
}

local ValueMap = {
	["Fork"] = 5,
	["Blood Ruby"] = 10,
	["Ruby"] = 10,
	["Amethyst"] = 10,
	["Spoon"] = 5,
	["Plate"] = 5,
	["Diamond"] = 10,
	["Chain"] = 5,
	["Sapphire"] = 10,
	["Goblet"] = 5,
	["Bowl"] = 5,
	["Emerald"] = 10,
	["Model"] = 67,
}

local function WorldToScreen(World)
	local Screen, InBounds = WorldToViewportPoint(Camera, World)
	return Vector2.new(Screen.X, Screen.Y), InBounds, Screen.Z
end

local function GetFont(Name)
	return DrawingFonts[Name]
end

local Trinket = {
	Started = false,
	Trinkets = {},
	Connections = {},

	Drawings = {},
	ESP = {
		Enabled = false,
		Font = "UI",
		MaxDistance = 1000,

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

		Value = {
			Enabled = false,
			Color = Color3.new(0, 1, 0),
			Transparency = 0,
		},
	},

	AutoGrab = {
		Enabled = false,
		RespectClickDetectorDistance = true,
		MaxDistance = 10,
	},
}

local function GetTrinketValue(TrinketName)
	return ValueMap[TrinketName]
end

function Trinket:UpdateESP()
	if not Trinket.ESP.Enabled then
		for _, Drawings in pairs(Trinket.Drawings) do
			if Drawings.Name then
				Drawings.Name.Visible = false
			end
			if Drawings.Distance then
				Drawings.Distance.Visible = false
			end
			if Drawings.Value then
				Drawings.Value.Visible = false
			end
		end
		return
	end

	local Character = Utility.GetCharacter(Player)
	if not Character then
		return
	end

	local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
	if not HumanoidRootPart then
		return
	end

	for TrinketModel, Data in pairs(Trinket.Trinkets) do
		local ID = Data.ID
		local Drawings = Trinket.Drawings[ID]

		if not Drawings then
			continue
		end

		if not Data.IsActive or not Data.Model then
			if Drawings.Name then
				Drawings.Name.Visible = false
			end
			if Drawings.Distance then
				Drawings.Distance.Visible = false
			end
			if Drawings.Value then
				Drawings.Value.Visible = false
			end
			continue
		end

		local Distance = (HumanoidRootPart.Position - TrinketModel.Position).Magnitude

		if Distance > Trinket.ESP.MaxDistance then
			if Drawings.Name then
				Drawings.Name.Visible = false
			end
			if Drawings.Distance then
				Drawings.Distance.Visible = false
			end
			if Drawings.Value then
				Drawings.Value.Visible = false
			end
			continue
		end

		local ScreenPos, OnScreen = WorldToScreen(TrinketModel.Position)

		if not OnScreen then
			if Drawings.Name then
				Drawings.Name.Visible = false
			end
			if Drawings.Distance then
				Drawings.Distance.Visible = false
			end
			if Drawings.Value then
				Drawings.Value.Visible = false
			end
			continue
		end

		local YOffset = 0

		if Trinket.ESP.Name.Enabled and Drawings.Name then
			Drawings.Name.Text = Data.Name or "Unknown"
			Drawings.Name.Position = Vector2.new(ScreenPos.X, ScreenPos.Y + YOffset)
			Drawings.Name.Color = Trinket.ESP.Name.Color
			Drawings.Name.Transparency = 1 - Trinket.ESP.Name.Transparency
			Drawings.Name.Font = GetFont(Trinket.ESP.Font)
			Drawings.Name.Visible = true
			YOffset = YOffset + 15
		else
			if Drawings.Name then
				Drawings.Name.Visible = false
			end
		end

		if Trinket.ESP.Distance.Enabled and Drawings.Distance then
			Drawings.Distance.Text = string.format("[%.1fm]", Distance)
			Drawings.Distance.Position = Vector2.new(ScreenPos.X, ScreenPos.Y + YOffset)
			Drawings.Distance.Color = Trinket.ESP.Distance.Color
			Drawings.Distance.Transparency = 1 - Trinket.ESP.Distance.Transparency
			Drawings.Distance.Font = GetFont(Trinket.ESP.Font)
			Drawings.Distance.Visible = true
			YOffset = YOffset + 14
		else
			if Drawings.Distance then
				Drawings.Distance.Visible = false
			end
		end

		if Trinket.ESP.Value.Enabled and Drawings.Value and Data.Value then
			Drawings.Value.Text = "$" .. tostring(Data.Value)
			Drawings.Value.Position = Vector2.new(ScreenPos.X, ScreenPos.Y + YOffset)
			Drawings.Value.Color = Trinket.ESP.Value.Color
			Drawings.Value.Transparency = 1 - Trinket.ESP.Value.Transparency
			Drawings.Value.Font = GetFont(Trinket.ESP.Font)
			Drawings.Value.Visible = true
		else
			if Drawings.Value then
				Drawings.Value.Visible = false
			end
		end
	end
end

function Trinket:InitESP()
	for _, Data in pairs(Trinket.Trinkets) do
		local ID = Data.ID

		local NameText = Drawing.new("Text")
		NameText.Text = ""
		NameText.Color = Trinket.ESP.Name.Color
		NameText.Size = 16
		NameText.Center = true
		NameText.Outline = true
		NameText.Visible = false
		NameText.Font = GetFont(Trinket.ESP.Font)

		local DistanceText = Drawing.new("Text")
		DistanceText.Text = ""
		DistanceText.Color = Trinket.ESP.Distance.Color
		DistanceText.Size = 16
		DistanceText.Center = true
		DistanceText.Outline = true
		DistanceText.Visible = false
		DistanceText.Font = GetFont(Trinket.ESP.Font)

		-- Create Value Text
		local ValueText = Drawing.new("Text")
		ValueText.Text = ""
		ValueText.Color = Trinket.ESP.Value.Color
		ValueText.Size = 16
		ValueText.Center = true
		ValueText.Outline = true
		ValueText.Visible = false
		ValueText.Font = GetFont(Trinket.ESP.Font)

		Trinket.Drawings[ID] = {
			Name = NameText,
			Distance = DistanceText,
			Value = ValueText,
		}
	end
end

function Trinket:HandleAutograb()
	local HeartbeatConnection = Heartbeat:Connect(function()
		if not Trinket.AutoGrab.Enabled then
			return
		end

		local Character, Humanoid = Utility.GetCharacter(Player), Utility.GetHumanoid(Player)
		if not Character or not Humanoid or Humanoid.Health <= 0 then
			return
		end

		local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
		if not HumanoidRootPart then
			return
		end

		for TrinketModel, Data in pairs(Trinket.Trinkets) do
			if not Data.IsActive or not Data.ClickDetector then
				continue
			end

			local Distance = (HumanoidRootPart.Position - TrinketModel.Position).Magnitude
			if Distance > Trinket.AutoGrab.MaxDistance then
				continue
			end

			if
				Trinket.AutoGrab.RespectClickDetectorDistance
				and Distance > Data.ClickDetector.MaxActivationDistance
			then
				continue
			end

			fireclickdetector(Data.ClickDetector)
		end
	end)

	table.insert(Trinket.Connections, HeartbeatConnection)
end

function Trinket:CacheTrinkets()
	for Index, WorkspaceTrinket in pairs(GetChildren(Trinkets)) do
		local Model = FindFirstChildWhichIsA(WorkspaceTrinket, "Model", true)
		local ClickDetector = FindFirstChildWhichIsA(WorkspaceTrinket, "ClickDetector", true)
		Trinket.Trinkets[WorkspaceTrinket] = {
			IsActive = Model ~= nil,
			ClickDetector = ClickDetector,
			Name = Model and Model.Name or nil,
			Model = Model,
			Value = Model and GetTrinketValue(Model.Name) or nil,
			ID = Index,
		}

		local AddedConnection = Utility.index(WorkspaceTrinket, "ChildAdded"):Connect(function(Child)
			local NewClickDetector = FindFirstChildWhichIsA(WorkspaceTrinket, "ClickDetector", true)
			local SharedTrinket = Trinket.Trinkets[WorkspaceTrinket]
			SharedTrinket.IsActive = true
			SharedTrinket.Name = Child.Name
			SharedTrinket.Value = GetTrinketValue(Child.Name) or nil
			SharedTrinket.ClickDetector = NewClickDetector or nil
			SharedTrinket.Model = Child
		end)

		local RemovedConnection = Utility.index(WorkspaceTrinket, "ChildRemoved"):Connect(function()
			local SharedTrinket = Trinket.Trinkets[WorkspaceTrinket]
			SharedTrinket.IsActive = false
			SharedTrinket.Name = nil
			SharedTrinket.Value = nil
			SharedTrinket.ClickDetector = nil
			SharedTrinket.Model = nil
		end)

		table.insert(Trinket.Connections, AddedConnection)
		table.insert(Trinket.Connections, RemovedConnection)
	end
end

function Trinket:Start()
	if Trinket.Started then
		return
	end
	Trinket.Started = true

	Trinket:CacheTrinkets()
	Trinket:InitESP()
	Trinket:HandleAutograb()

	local UpdateConnection = Heartbeat:Connect(function()
		Trinket:UpdateESP()
	end)
	table.insert(Trinket.Connections, UpdateConnection)
end

function Trinket:Stop()
	if not Trinket.Started then
		return
	end
	Trinket.Started = false

	for _, Connection in pairs(Trinket.Connections) do
		if typeof(Connection) == "RBXScriptConnection" then
			Connection:Disconnect()
		end
	end
	table.clear(Trinket.Connections)

	-- Clean up all drawings
	for _, Drawings in pairs(Trinket.Drawings) do
		if Drawings.Name then
			Drawings.Name:Remove()
		end
		if Drawings.Distance then
			Drawings.Distance:Remove()
		end
		if Drawings.Value then
			Drawings.Value:Remove()
		end
	end
	table.clear(Trinket.Drawings)
end

return Trinket
