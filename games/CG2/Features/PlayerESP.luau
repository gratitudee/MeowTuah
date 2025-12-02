local Services, Utility, ESP =
	LoadModule("core/Services.lua"), LoadModule("core/Utility.lua"), LoadModule("modules/PlayerESP.lua")
local Players = Services.Players
local RunService = Services.RunService

local Heartbeat = Utility.index(RunService, "Heartbeat")
local PlayerAdded, PlayerRemoving = Utility.index(Players, "PlayerAdded"), Utility.index(Players, "PlayerRemoving")
local GetChildren = Utility.GetChildren

local PlayerESP = {
	Enabled = false,
	AliveCheck = false,

	ScriptConnections = {},
	Data = {},
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

	Health = {
		Enabled = false,
	},
}

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
		local Drawings = Dictionary.Drawings
		local Bounds = ESP:GetBoundingBox(Dictionary.Bodyparts)
		if not Bounds then -- nothing to draw with
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

	PlayerDict.Character = Player.Character

	for _, Bodypart in pairs(PlayerDict.Character:GetDescendants()) do
		if PlayerESP:ValidatePart(Bodypart) then
			table.insert(PlayerDict.Bodyparts, Bodypart)
		end
	end

	PlayerDict.Connections.CharacterAdded = Player.CharacterAdded:Connect(function(Character)
		table.clear(PlayerDict.Bodyparts)
		PlayerDict.Character = Character
		PlayerDict.Connections.CharacterDescendantAdded = Character.DescendantAdded:Connect(function(Child)
			local Valid = PlayerESP:ValidatePart(Child)
			if Valid then
				table.insert(PlayerDict.Bodyparts, Child)
			end
		end)

		PlayerDict.Connections.CharacterRemoved = Character:GetPropertyChangedSignal("Parent"):Connect(function()
			if not Character.Parent then
				PlayerDict.Connections.CharacterDescendantAdded:Disconnect()
				PlayerDict.Connections.CharacterDescendantAdded = nil

				PlayerDict.Connections.CharacterRemoved:Disconnect()
				PlayerDict.Connections.CharacterRemoved = nil
			end
		end)
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
