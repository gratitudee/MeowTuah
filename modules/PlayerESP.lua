local Services, Utility = LoadModule("core/Services.lua"), LoadModule("core/Utility.lua")
local Workspace = Services.Workspace
local RunService = Services.RunService

-- Variables
local Player = Utility.GetPlayer()
local Camera = Utility.index(Workspace, "CurrentCamera")
local WorldToViewportPoint = Utility.index(Camera, "WorldToViewportPoint")
local Heartbeat = Utility.index(RunService, "Heartbeat")
local FindFirstChild = Utility.FindFirstChild
local FindFirstChildWhichIsA = Utility.FindFirstChildWhichIsA
local GetChildren = Utility.GetChildren
local CubeCorners = {
	Vector3.new(-1, -1, -1),
	Vector3.new(-1, -1, 1),
	Vector3.new(-1, 1, -1),
	Vector3.new(-1, 1, 1),
	Vector3.new(1, -1, -1),
	Vector3.new(1, -1, 1),
	Vector3.new(1, 1, -1),
	Vector3.new(1, 1, 1),
}

local PlayerESP = {}

-- Utility Functions
local function WorldToScreen(World)
	local Screen, InBounds = WorldToViewportPoint(Camera, World)
	return Vector2.new(Screen.X, Screen.Y), InBounds, Screen.Z
end

-- Internal Functions
function PlayerESP:DrawBox()
	local Outer = Drawing.new("Square")
	Outer.Thickness = 4
	Outer.Filled = false
	Outer.Color = Color3.new(0, 0, 0)
	Outer.Transparency = 1
	Outer.Visible = false

	local Middle = Drawing.new("Square")
	Middle.Thickness = 2
	Middle.Filled = false
	Middle.Color = Color3.new(1, 1, 1)
	Middle.Transparency = 1
	Middle.Visible = false

	local Inner = Drawing.new("Square")
	Inner.Thickness = 1
	Inner.Filled = false
	Inner.Color = Color3.new(1, 1, 1)
	Inner.Transparency = 1
	Inner.Visible = false

	return {
		Outer = Outer,
		Middle = Middle,
		Inner = Inner,

		SetPosition = function(self, x, y, w, h)
			local Position, Size = Vector2.new(x, y), Vector2.new(w, h)
			self.Outer.Position = Position
			self.Outer.Size = Size

			self.Middle.Position = Position
			self.Middle.Size = Size

			self.Inner.Position = Position
			self.Inner.Size = Size

			self.Outer.Visible = true
			self.Middle.Visible = true
			self.Inner.Visible = true
		end,

		SetColor = function(self, color, alpha)
			self.Middle.Color = color
			self.Middle.Transparency = 1 - alpha
			self.Outer.Transparency = 1 - alpha
			self.Inner.Transparency = 1 - alpha
		end,

		SetVisible = function(self, state)
			self.Outer.Visible = state
			self.Middle.Visible = state
			self.Inner.Visible = state
		end,

		Remove = function(self)
			self.Outer:Remove()
			self.Middle:Remove()
			self.Inner:Remove()
		end,
	}
end

function PlayerESP:DrawBoxFilled()
	local Box = Drawing.new("Square")
	Box.Filled = true
	Box.Color = Color3.new(1, 1, 1)
	Box.Transparency = 1
	Box.Visible = false

	return {
		Box = Box,

		SetPosition = function(self, x, y, w, h)
			self.Box.Position = Vector2.new(x, y)
			self.Box.Size = Vector2.new(w, h)
			self.Box.Visible = true
		end,

		SetColor = function(self, color, transparency)
			self.Box.Color = color
			self.Box.Transparency = 1 - transparency
		end,

		SetVisible = function(self, state)
			self.Box.Visible = state
		end,

		Remove = function(self)
			self.Box:Remove()
		end,
	}
end

function PlayerESP:GetBoundingBox(Parts)
	local MinX, MinY = math.huge, math.huge
	local MaxX, MaxY = -math.huge, -math.huge
	local FoundVisible = false

	for _, Part in ipairs(Parts) do
		if Part:IsA("BasePart") then
			local CFrame = Part.CFrame
			local HalfSize = Part.Size * 0.5

			for _, Corner in ipairs(CubeCorners) do
				local WorldPos = CFrame:PointToWorldSpace(HalfSize * Corner)
				local ScreenPos, OnScreen = WorldToScreen(WorldPos)

				if OnScreen then
					FoundVisible = true

					local X, Y = ScreenPos.X, ScreenPos.Y

					if X < MinX then
						MinX = X
					end
					if X > MaxX then
						MaxX = X
					end
					if Y < MinY then
						MinY = Y
					end
					if Y > MaxY then
						MaxY = Y
					end
				end
			end
		end
	end

	if not FoundVisible then
		return nil
	end

	return {
		X = MinX,
		Y = MinY,
		W = MaxX - MinX,
		H = MaxY - MinY,
	}
end

return PlayerESP
