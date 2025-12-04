local Services, Utility = LoadModule("core/Services.lua"), LoadModule("core/Utility.lua")

local RunService = Services.RunService
local VirtualInputManager = Services.VirtualInputManager
local Player = Utility.GetPlayer()
local SendKeyEvent = Utility.index(VirtualInputManager, "SendKeyEvent")

local Movement = {
	Connections = {},
	AutoSlide = {
		Enabled = false,
		Character = nil,
		CurrentReplicator = nil,
		Blocklist = {
			"SlideCooldown",
			"Stun",
			"TrueStun",
			"Carried",
			"Downed",
			"Blocking",
			"Swinging",
			"Glorying",
			"Gloried",
			"Executing",
			"Executed",
			"Doing",
			"BeingDone",
			"Critting",
			"Crouching",
			"Knockdown",
		},
	},
}

local function SendKeyUpKeyDown(Key, Delay)
	SendKeyEvent(VirtualInputManager, true, Key, false, nil)
	task.wait(Delay)
	SendKeyEvent(VirtualInputManager, false, Key, false, nil)
end

-- Autoslide Funcs
function Movement.AutoSlide:GetReplicator()
	for _, trash in pairs(getgc(true)) do
		if type(trash) == "table" and rawget(trash, "Tokens") and rawget(trash, "Listeners") then
			if trash.Character == Movement.AutoSlide.Character then
				Movement.AutoSlide.CurrentReplicator = trash
				return trash
			end
		end
	end
	return nil
end

function Movement.AutoSlide:CanSlide()
	if not Movement.AutoSlide.CurrentReplicator then
		return false
	end

	local replicator = Movement.AutoSlide.CurrentReplicator

	for _, state in pairs(Movement.AutoSlide.Blocklist) do
		if replicator:Has(state) then
			return false
		end
	end

	return replicator:Has("Sprinting")
end

function Movement.AutoSlide:DoSlide()
	SendKeyUpKeyDown(Enum.KeyCode.LeftControl, 0.01)
	SendKeyUpKeyDown(Enum.KeyCode.Space, 0.01)
end

function Movement.AutoSlide:Start()
	local CharacterAdded = Utility.index(Player, "CharacterAdded"):Connect(function(Character)
		Movement.AutoSlide.CurrentReplicator = nil
		Movement.AutoSlide.Character = Character
	end)

	local Heartbeat = Utility.index(RunService, "Heartbeat"):Connect(function()
		if not Movement.AutoSlide.Enabled then
			return
		end

		if not Movement.AutoSlide.Character then
			Movement.AutoSlide.Character = Utility.index(Player, "Character")
			return
		end

		if not Movement.AutoSlide.CurrentReplicator then
			Movement.AutoSlide:GetReplicator()
			return
		end

		if Movement.AutoSlide:CanSlide() then
			Movement.AutoSlide:DoSlide()
		end
	end)

	table.insert(Movement.Connections, CharacterAdded)
	table.insert(Movement.Connections, Heartbeat)
end

function Movement:Start()
	Movement.AutoSlide:Start()
end

function Movement:Stop()
	for _, Connections in pairs(Movement.Connections) do
		Connections:Disconnect()
		Connections = nil
	end
end

return Movement
