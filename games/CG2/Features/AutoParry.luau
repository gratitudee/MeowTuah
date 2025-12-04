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
	State = { Parrying = false },
}

function AutoParry:SimulateParry()
	if self.State.Parrying then
		return
	end

	self.State.Parrying = true
	SendKeyEvent(VirtualInputManager, true, self.ParryKey, false, nil)

	task.delay(math.random(0.045, 0.087), function()
		self.State.Parrying = false
		SendKeyEvent(VirtualInputManager, false, self.ParryKey, false, nil)
	end)
end

function AutoParry:IsInRange(EnemyRootPart)
	local LocalCharacter = Utility.GetCharacter(Player)
	local LocalRootPart = LocalCharacter and FindFirstChild(LocalCharacter, "HumanoidRootPart")

	if not LocalRootPart or not EnemyRootPart then
		return false
	end

	return (EnemyRootPart.Position - LocalRootPart.Position).Magnitude <= self.MaxDistance
end

function AutoParry:OnMarkerReached(PlayerObj, Character)
	if not self.Enabled or PlayerObj == Player then
		return
	end

	local EnemyRootPart = FindFirstChild(Character, "HumanoidRootPart")
	if self:IsInRange(EnemyRootPart) then
		self:SimulateParry()
	end
end

function AutoParry:CleanupAnimationConnections(PlayerName, AnimationId)
	local PlayerConn = self.PlayerConnections[PlayerName]
	if not PlayerConn or not PlayerConn[AnimationId] then
		return
	end

	for _, Connection in pairs(PlayerConn[AnimationId]) do
		if typeof(Connection) == "RBXScriptConnection" then
			Connection:Disconnect()
		end
	end
	PlayerConn[AnimationId] = nil

	if next(PlayerConn) == nil then
		self.PlayerConnections[PlayerName] = nil
	end
end

function AutoParry:SetupAnimationTracking(PlayerObj, Character)
	local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
	local Animator = Humanoid and FindFirstChildOfClass(Humanoid, "Animator")
	if not Animator then
		return
	end

	local PlayerName = PlayerObj.Name
	if not self.PlayerConnections[PlayerName] then
		self.PlayerConnections[PlayerName] = {}
	end

	if self.PlayerConnections[PlayerName].AnimationPlayed then
		self.PlayerConnections[PlayerName].AnimationPlayed:Disconnect()
	end

	self.PlayerConnections[PlayerName].AnimationPlayed = Utility.index(Animator, "AnimationPlayed")
		:Connect(function(Track)
			local AnimationId = Track.Animation.AnimationId
			local AnimConn = self.PlayerConnections[PlayerName]

			if not AnimConn[AnimationId] then
				AnimConn[AnimationId] = {}
			end

			if AnimConn[AnimationId].Pause then
				AnimConn[AnimationId].Pause:Disconnect()
			end
			AnimConn[AnimationId].Pause = Utility.GetMarkerReachedSignal(Track, "Pause"):Connect(function()
				self:OnMarkerReached(PlayerObj, Character)
			end)

			if AnimConn[AnimationId].Ended then
				AnimConn[AnimationId].Ended:Disconnect()
			end
			AnimConn[AnimationId].Ended = Track.Ended:Connect(function()
				self:CleanupAnimationConnections(PlayerName, AnimationId)
			end)
		end)
end

function AutoParry:MonitorPlayer(PlayerObj)
	local function SetupCharacter(Character)
		if Character then
			self:SetupAnimationTracking(PlayerObj, Character)
		end
	end

	local PlayerName = PlayerObj.Name
	if not self.PlayerConnections[PlayerName] then
		self.PlayerConnections[PlayerName] = {}
	end

	local Character = Utility.GetCharacter(PlayerObj)
	if Character then
		SetupCharacter(Character)
	end

	if self.PlayerConnections[PlayerName].CharacterAdded then
		self.PlayerConnections[PlayerName].CharacterAdded:Disconnect()
	end

	self.PlayerConnections[PlayerName].CharacterAdded = Utility.index(PlayerObj, "CharacterAdded")
		:Connect(SetupCharacter)
end

function AutoParry:CleanupPlayer(PlayerObj)
	local PlayerName = PlayerObj.Name
	local PlayerConn = self.PlayerConnections[PlayerName]
	if not PlayerConn then
		return
	end

	for Key, Connection in pairs(PlayerConn) do
		if typeof(Connection) == "RBXScriptConnection" then
			Connection:Disconnect()
		elseif type(Connection) == "table" then
			for _, SubConnection in pairs(Connection) do
				if typeof(SubConnection) == "RBXScriptConnection" then
					SubConnection:Disconnect()
				end
			end
		end
	end

	self.PlayerConnections[PlayerName] = nil
end

function AutoParry:StartPlayerMonitoring()
	local GetChildren = Utility.GetChildren

	for _, PlayerObj in ipairs(GetChildren(Players)) do
		if PlayerObj:IsA("Player") and PlayerObj ~= Player then
			self:MonitorPlayer(PlayerObj)
		end
	end

	table.insert(
		self.Connections,
		Utility.index(Players, "PlayerAdded"):Connect(function(PlayerObj)
			self:MonitorPlayer(PlayerObj)
		end)
	)

	table.insert(
		self.Connections,
		Utility.index(Players, "PlayerRemoving"):Connect(function(PlayerObj)
			self:CleanupPlayer(PlayerObj)
		end)
	)
end

function AutoParry:Start()
	self:StartPlayerMonitoring()
end

function AutoParry:Stop()
	for _, Connection in ipairs(self.Connections) do
		if typeof(Connection) == "RBXScriptConnection" then
			Connection:Disconnect()
		end
	end
	table.clear(self.Connections)

	for PlayerName, PlayerConn in pairs(self.PlayerConnections) do
		self:CleanupPlayer(Players:FindFirstChild(PlayerName))
	end
	table.clear(self.PlayerConnections)

	self.State.Parrying = false
end

return AutoParry
