local Services, Utility = LoadModule("core/Services.lua"), LoadModule("core/Utility.lua")

local Players = Services.Players
local VirtualInputManager = Services.VirtualInputManager

local Player = Utility.GetPlayer()
local SendKeyEvent = Utility.index(VirtualInputManager, "SendKeyEvent")
local FindFirstChild = Utility.FindFirstChild
local FindFirstChildOfClass = Utility.FindFirstChildOfClass

local AutoParry = {
	Enabled = false,
	MaxDistance = 10,
	ParryKey = Enum.KeyCode.F,
	Connections = {},
	PlayerConnections = {},
	State = {
		Parrying = false,
	},
}

function AutoParry:SimulateParry()
	if AutoParry.State.Parrying then
		return
	end

	AutoParry.State.Parrying = true
	SendKeyEvent(VirtualInputManager, true, AutoParry.ParryKey, false, nil)

	local KeyPressDelay = math.random(0.045, 0.087)
	task.delay(KeyPressDelay, function()
		AutoParry.State.Parrying = false
		SendKeyEvent(VirtualInputManager, false, AutoParry.ParryKey, false, nil)
	end)
end

function AutoParry:IsInRange(EnemyRootPart)
	local LocalCharacter = Utility.GetCharacter(Player)
	local LocalRootPart = LocalCharacter and FindFirstChild(LocalCharacter, "HumanoidRootPart")

	if not LocalRootPart or not EnemyRootPart then
		return false
	end

	local Distance = (EnemyRootPart.Position - LocalRootPart.Position).Magnitude
	return Distance <= AutoParry.MaxDistance
end

function AutoParry:OnMarkerReached(PlayerObj, Character)
	if not AutoParry.Enabled or PlayerObj == Player then
		return
	end

	local EnemyRootPart = FindFirstChild(Character, "HumanoidRootPart")
	if not AutoParry:IsInRange(EnemyRootPart) then
		return
	end

	if AutoParry:IsInRange(EnemyRootPart) then
		AutoParry:SimulateParry()
	end
end

function AutoParry:CleanupAnimationConnections(PlayerName, AnimationId)
	local MarkerKey = PlayerName .. "_" .. AnimationId .. "_Pause"
	local EndedKey = PlayerName .. "_" .. AnimationId .. "_Ended"

	if AutoParry.PlayerConnections[MarkerKey] then
		AutoParry.PlayerConnections[MarkerKey]:Disconnect()
		AutoParry.PlayerConnections[MarkerKey] = nil
	end

	if AutoParry.PlayerConnections[EndedKey] then
		AutoParry.PlayerConnections[EndedKey]:Disconnect()
		AutoParry.PlayerConnections[EndedKey] = nil
	end
end

function AutoParry:SetupAnimationTracking(PlayerObj, Character)
	local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
	local Animator = Humanoid and FindFirstChildOfClass(Humanoid, "Animator")

	if not Animator then
		return
	end

	local ConnectionKey = PlayerObj.Name .. "_AnimationPlayed"
	if AutoParry.PlayerConnections[ConnectionKey] then
		AutoParry.PlayerConnections[ConnectionKey]:Disconnect()
	end

	AutoParry.PlayerConnections[ConnectionKey] = Utility.index(Animator, "AnimationPlayed"):Connect(function(Track)
		local AnimationId = Track.Animation.AnimationId
		local MarkerKey = PlayerObj.Name .. "_" .. AnimationId .. "_Pause"

		if AutoParry.PlayerConnections[MarkerKey] then
			AutoParry.PlayerConnections[MarkerKey]:Disconnect()
		end

		AutoParry.PlayerConnections[MarkerKey] = Utility.GetMarkerReachedSignal(Track, "Pause"):Connect(function()
			AutoParry:OnMarkerReached(PlayerObj, Character)
		end)

		local EndedKey = PlayerObj.Name .. "_" .. AnimationId .. "_Ended"
		if AutoParry.PlayerConnections[EndedKey] then
			AutoParry.PlayerConnections[EndedKey]:Disconnect()
		end

		AutoParry.PlayerConnections[EndedKey] = Track.Ended:Connect(function()
			AutoParry:CleanupAnimationConnections(PlayerObj.Name, AnimationId)
		end)
	end)
end

function AutoParry:MonitorPlayer(PlayerObj)
	local function SetupCharacter(Character)
		if not Character then
			return
		end
		AutoParry:SetupAnimationTracking(PlayerObj, Character)
	end

	local Character = Utility.GetCharacter(PlayerObj)
	if Character then
		SetupCharacter(Character)
	end

	local CharConnectionKey = PlayerObj.Name .. "_CharacterAdded"
	if AutoParry.PlayerConnections[CharConnectionKey] then
		AutoParry.PlayerConnections[CharConnectionKey]:Disconnect()
	end

	AutoParry.PlayerConnections[CharConnectionKey] = Utility.index(PlayerObj, "CharacterAdded")
		:Connect(function(NewCharacter)
			SetupCharacter(NewCharacter)
		end)
end

function AutoParry:CleanupPlayer(PlayerObj)
	for Key, Connection in pairs(AutoParry.PlayerConnections) do
		if type(Key) == "string" and string.find(Key, PlayerObj.Name) then
			if typeof(Connection) == "RBXScriptConnection" then
				Connection:Disconnect()
			end
			AutoParry.PlayerConnections[Key] = nil
		end
	end
end

function AutoParry:StartPlayerMonitoring()
	local GetChildren = Utility.GetChildren

	for _, PlayerObj in ipairs(GetChildren(Players)) do
		if PlayerObj:IsA("Player") and PlayerObj ~= Player then
			AutoParry:MonitorPlayer(PlayerObj)
		end
	end

	local PlayerAdded = Utility.index(Players, "PlayerAdded"):Connect(function(PlayerObj)
		AutoParry:MonitorPlayer(PlayerObj)
	end)

	local PlayerRemoving = Utility.index(Players, "PlayerRemoving"):Connect(function(PlayerObj)
		AutoParry:CleanupPlayer(PlayerObj)
	end)

	table.insert(AutoParry.Connections, PlayerAdded)
	table.insert(AutoParry.Connections, PlayerRemoving)
end

function AutoParry:Start()
	AutoParry:StartPlayerMonitoring()
end

function AutoParry:Stop()
	for _, Connection in pairs(AutoParry.Connections) do
		if typeof(Connection) == "RBXScriptConnection" then
			Connection:Disconnect()
		end
	end
	table.clear(AutoParry.Connections)

	for Key, Connection in pairs(AutoParry.PlayerConnections) do
		if typeof(Connection) == "RBXScriptConnection" then
			Connection:Disconnect()
		end
	end
	table.clear(AutoParry.PlayerConnections)

	AutoParry.State.Parrying = false
end

return AutoParry
