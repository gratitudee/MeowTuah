-- References
local Services, Utility = LoadModule("core/Services.lua"), LoadModule("core/Utility.lua")
local Workspace = Services.Workspace
local RunService = Services.RunService
local CoreGui = Services.CoreGui
local TextService = Utility.GetService("TextService")

local Player = Utility.GetPlayer()
local GetTextSize = Utility.index(TextService, "GetTextSize")
local Heartbeat = Utility.index(RunService, "Heartbeat")
local FindFirstChild = Utility.FindFirstChild
local FindFirstChildOfClass = Utility.FindFirstChildOfClass
local FindFirstChildWhichIsA = Utility.FindFirstChildWhichIsA
local GetChildren = Utility.GetChildren
local Trinkets = FindFirstChild(Workspace, "Trinkets") or FindFirstChild(Workspace, "TrinketSpawns")

local Trinket = {
	Started = false,
	Trinkets = {},
	Connections = {},

	ESP = {
		Enabled = false,
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
	return 0
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

		local RemovedConnection = Utility.index(WorkspaceTrinket, "ChildRemoved"):Connect(function(Child)
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
	print("TRINKET: STARTED")
	if Trinket.Started then
		return
	end
	Trinket.Started = true

	Trinket:CacheTrinkets()
	Trinket:HandleAutograb()
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
end

return Trinket
