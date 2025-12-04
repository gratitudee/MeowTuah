local Services = LoadModule("core/Services.lua")
local Utility = LoadModule("core/Utility.lua")
local ESP = LoadModule("modules/PlayerESP.lua")

local Players = Services.Players
local Workspace = Services.Workspace
local RunService = Services.RunService
local CoreGui = gethui and gethui() or Services.CoreGui

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
	ViewportXRay = {
		Enabled = false,
		Objects = {
			ScreenUI = nil,
			ViewportFrame = nil,
			Camera = nil,
			Connections = {},
			RayIgnore = {},
			Clones = {},
		},
	},
}

local PlayerESP = setmetatable(DefaultConfig, {})
PlayerESP.ScriptConnections = {}
PlayerESP.Data = {}

--// Constants
local MAX_VISIBILITY_DISTANCE = 100
local MIN_BOUNDING_SIZE = 3

--// Utility Functions
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

local function SafeDestroy(instance)
	if instance and typeof(instance) == "Instance" then
		pcall(function()
			if instance.Parent then
				instance:Destroy()
			end
		end)
	end
end

function PlayerESP.ViewportXRay:Init()
	local objs = self.Objects

	if objs.ScreenUI and objs.ScreenUI.Parent then
		return
	end

	objs.ScreenUI = Instance.new("ScreenGui")
	objs.ScreenUI.Name = "ViewportESP"
	objs.ScreenUI.ResetOnSpawn = false
	objs.ScreenUI.IgnoreGuiInset = true
	objs.ScreenUI.DisplayOrder = 999999
	objs.ScreenUI.Parent = CoreGui

	objs.ViewportFrame = Instance.new("ViewportFrame")
	objs.ViewportFrame.Name = "ESPViewport"
	objs.ViewportFrame.Size = UDim2.fromScale(1, 1)
	objs.ViewportFrame.BackgroundTransparency = 1
	objs.ViewportFrame.LightDirection = Vector3.new(-1, -1, -1)
	objs.ViewportFrame.Ambient = Color3.fromRGB(120, 120, 120)
	objs.ViewportFrame.Parent = objs.ScreenUI

	objs.Camera = Instance.new("Camera")
	objs.Camera.FieldOfView = 70
	objs.ViewportFrame.CurrentCamera = objs.Camera

	objs.Clones = {}
	objs.Connections = {}
	objs.RayIgnore = { LocalPlayer.Character or Instance.new("Model") }

	local charAddedConn = Utility.index(LocalPlayer, "CharacterAdded"):Connect(function(char)
		objs.RayIgnore[1] = char
	end)
	table.insert(objs.Connections, charAddedConn)
end

function PlayerESP.ViewportXRay:CreateClone(character)
	if not character or not character.PrimaryPart then
		return nil
	end

	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = false

	for _, obj in pairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.Massless = true
			obj.CastShadow = false

			if not obj:GetAttribute("OrigTrans") then
				obj:SetAttribute("OrigTrans", obj.Transparency)
			end
		elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
			if not obj:GetAttribute("OrigTrans") then
				obj:SetAttribute("OrigTrans", obj.Transparency)
			end
		elseif obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
			obj:Destroy()
		elseif obj:IsA("Humanoid") then
			obj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			obj.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end
	end

	clone.Parent = self.Objects.ViewportFrame
	return clone
end

function PlayerESP.ViewportXRay:IsVisible(character)
	if not character then
		return false
	end

	local hrp = Utility.FindFirstChild(character, "HumanoidRootPart")
	if not hrp then
		return false
	end

	local cam = Utility.index(Workspace, "CurrentCamera")
	if not cam then
		return false
	end

	local pos = hrp.Position
	local camPos = cam.CFrame.Position

	local _, onScreen = WorldToScreen(pos)
	if not onScreen then
		return false
	end

	local distance = (pos - camPos).Magnitude
	if distance > MAX_VISIBILITY_DISTANCE then
		return false
	end

	local _, size = character:GetBoundingBox()
	if size.Magnitude < MIN_BOUNDING_SIZE then
		return false
	end

	local direction = (pos - camPos)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = self.Objects.RayIgnore
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(camPos, direction, params)
	return not result or result.Instance:IsDescendantOf(character)
end

function PlayerESP.ViewportXRay:RefreshCharacterClone(player)
	if not player then
		return
	end

	local objs = self.Objects
	self:ClearPlayer(player)

	local char = player.Character
	if not char or not char.PrimaryPart then
		return
	end

	local clone = self:CreateClone(char)
	if clone then
		objs.Clones[player] = clone
	end
end

function PlayerESP.ViewportXRay:ClearPlayer(player)
	local objs = self.Objects
	if not objs or not objs.Clones then
		return
	end

	local clone = objs.Clones[player]
	if clone then
		SafeDestroy(clone)
		objs.Clones[player] = nil
	end
end

function PlayerESP.ViewportXRay:ClearAll()
	local objs = self.Objects
	if not objs or not objs.Clones then
		return
	end

	for player, clone in pairs(objs.Clones) do
		SafeDestroy(clone)
		objs.Clones[player] = nil
	end
end

function PlayerESP.ViewportXRay:UpdateCloneCFrames(character, clone)
	if not character or not clone then
		return
	end

	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local clonePart = clone:FindFirstChild(part.Name, true)
			if clonePart and clonePart:IsA("BasePart") then
				clonePart.CFrame = part.CFrame
			end
		end
	end

	for _, obj in pairs(character:GetChildren()) do
		if obj:IsA("Accessory") or obj:IsA("Tool") then
			local cloneObj = clone:FindFirstChild(obj.Name)
			if cloneObj then
				for _, part in pairs(obj:GetDescendants()) do
					if part:IsA("BasePart") then
						local clonePart = cloneObj:FindFirstChild(part.Name, true)
						if clonePart and clonePart:IsA("BasePart") then
							clonePart.CFrame = part.CFrame
						end
					end
				end
			else
				self:RefreshCharacterClone(character.Parent)
				return
			end
		end
	end

	for _, cloneObj in pairs(clone:GetChildren()) do
		if (cloneObj:IsA("Accessory") or cloneObj:IsA("Tool")) and cloneObj.Name ~= "HumanoidRootPart" then
			local characterObj = character:FindFirstChild(cloneObj.Name)
			if not characterObj then
				self:RefreshCharacterClone(character.Parent)
				return
			end
		end
	end
end

function PlayerESP.ViewportXRay:UpdatePlayer(playerDict)
	if not PlayerESP.Enabled or not self.Enabled then
		return
	end

	local player = playerDict.Player
	if not player or player == LocalPlayer then
		return
	end

	local objs = self.Objects

	if not objs.ViewportFrame or not objs.ViewportFrame.Parent then
		self:Init()
		objs = self.Objects
	end

	local cam = Utility.index(Workspace, "CurrentCamera")
	if not cam then
		return
	end

	if objs.Camera then
		objs.Camera.CFrame = cam.CFrame
	end

	local char = playerDict.Character
	local clone = objs.Clones[player]

	if not char then
		if clone then
			self:ClearPlayer(player)
		end
		return
	end

	if not clone or not clone.Parent then
		self:RefreshCharacterClone(player)
		clone = objs.Clones[player]
		if not clone then
			return
		end
	end

	local visible = self:IsVisible(char)
	self:UpdateCloneCFrames(char, clone)

	for _, part in pairs(clone:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
			local origTrans = part:GetAttribute("OrigTrans") or 0
			part.Transparency = (not visible) and origTrans or 1
		end
	end
end

function PlayerESP.ViewportXRay:Cleanup()
	local objs = self.Objects

	if objs.Connections then
		for _, conn in pairs(objs.Connections) do
			if conn and typeof(conn) == "RBXScriptConnection" then
				pcall(function()
					conn:Disconnect()
				end)
			end
		end
		objs.Connections = {}
	end

	self:ClearAll()

	if objs.ViewportFrame then
		SafeDestroy(objs.ViewportFrame)
		objs.ViewportFrame = nil
	end

	if objs.ScreenUI then
		SafeDestroy(objs.ScreenUI)
		objs.ScreenUI = nil
	end

	objs.Camera = nil

	objs.Clones = {}
	objs.RayIgnore = {}
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

	if self.ViewportXRay and self.ViewportXRay.Enabled then
		self.ViewportXRay:UpdatePlayer(Dictionary)
	end

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

		if self.ViewportXRay and self.ViewportXRay.Enabled then
			self.ViewportXRay:RefreshCharacterClone(Player)
		end

		PlayerDict.Connections.ChildAdded = Character.ChildAdded:Connect(function(Child)
			if self:ValidatePart(Child) then
				table.insert(PlayerDict.Bodyparts, Child)
			end

			if (Child:IsA("Accessory") or Child:IsA("Tool")) and self.ViewportXRay and self.ViewportXRay.Enabled then
				self.ViewportXRay:RefreshCharacterClone(Player)
			end
		end)

		PlayerDict.Connections.ChildRemoving = Character.ChildRemoved:Connect(function(Child)
			for I, Part in ipairs(PlayerDict.Bodyparts) do
				if Part == Child then
					table.remove(PlayerDict.Bodyparts, I)
					break
				end
			end

			if (Child:IsA("Accessory") or Child:IsA("Tool")) and self.ViewportXRay and self.ViewportXRay.Enabled then
				self.ViewportXRay:RefreshCharacterClone(Player)
			end
		end)
	end)

	PlayerDict.Connections.CharacterRemoved = Player.CharacterRemoving:Connect(function()
		PlayerDict.Character = nil
		PlayerDict.Bodyparts = {}

		if self.ViewportXRay then
			self.ViewportXRay:ClearPlayer(Player)
		end

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
		if Player ~= LocalPlayer then
			self:InitPlayer(Player)
		end
	end

	local PlayerAdded = Utility.index(Players, "PlayerAdded"):Connect(function(Player)
		if Player ~= LocalPlayer then
			self:InitPlayer(Player)
		end
	end)

	local PlayerRemoving = Utility.index(Players, "PlayerRemoving"):Connect(function(Player)
		local PlayerDict = self.Data[Player.Name]
		if not PlayerDict then
			return
		end

		for _, Connection in pairs(PlayerDict.Connections) do
			if Connection and typeof(Connection) == "RBXScriptConnection" then
				pcall(function()
					Connection:Disconnect()
				end)
			end
		end

		for _, Drawing in pairs(PlayerDict.Drawings) do
			pcall(function()
				Drawing:Remove()
			end)
		end

		if self.ViewportXRay then
			self.ViewportXRay:ClearPlayer(Player)
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
			if self.ViewportXRay then
				self.ViewportXRay:ClearAll()
				self.ViewportXRay:Cleanup()
			end

			for _, Dict in pairs(self.Data) do
				HideAllDrawings(Dict.Drawings)
			end

			return
		end

		if self.ViewportXRay and self.ViewportXRay.Enabled and not self.ViewportXRay.Objects.ViewportFrame then
			self.ViewportXRay:Init()
		elseif self.ViewportXRay and not self.ViewportXRay.Enabled then
			self.ViewportXRay:ClearAll()
			self.ViewportXRay:Cleanup()
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
			pcall(function()
				self:DrawPlayer(RenderInfo.List[RenderInfo.Index])
			end)

			RenderInfo.Index = RenderInfo.Index + 1
			Processed = Processed + 1
		end
	end)

	table.insert(self.ScriptConnections, PlayerAdded)
	table.insert(self.ScriptConnections, PlayerRemoving)
	table.insert(self.ScriptConnections, RenderConnection)
end

function PlayerESP:Stop()
	if self.ViewportXRay then
		self.ViewportXRay:Cleanup()
	end

	for PlayerName, PlayerDict in pairs(self.Data) do
		for _, Connection in pairs(PlayerDict.Connections) do
			if Connection and typeof(Connection) == "RBXScriptConnection" then
				pcall(function()
					Connection:Disconnect()
				end)
			end
		end

		for _, Drawing in pairs(PlayerDict.Drawings) do
			pcall(function()
				Drawing:Remove()
			end)
		end

		self.Data[PlayerName] = nil
	end

	self.Data = {}

	for _, Connection in pairs(self.ScriptConnections) do
		if Connection and typeof(Connection) == "RBXScriptConnection" then
			pcall(function()
				Connection:Disconnect()
			end)
		end
	end

	self.ScriptConnections = {}
end

return PlayerESP
