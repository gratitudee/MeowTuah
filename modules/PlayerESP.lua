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
			self.Inner.Color = color
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

function PlayerESP:DrawText()
	local Text = Drawing.new("Text")
	Text.Outline = true
	Text.Color = Color3.new(1, 1, 1)
	Text.OutlineColor = Color3.new(0, 0, 0)
	Text.Visible = false
	Text.Transparency = 1

	return {
		Text = Text,

		SetPosition = function(self, x, y)
			self.Text.Position = Vector2.new(x, y)
			self.Text.Visible = true
		end,

		SetColor = function(self, TextColor, Transparency)
			self.Text.Color = TextColor
			self.Text.Transparency = 1 - Transparency
		end,

		SetVisible = function(self, state)
			self.Text.Visible = state
		end,

		SetText = function(self, text)
			self.Text.Text = text
		end,

		Remove = function(self)
			self.Text:Remove()
		end,
	}
end

function PlayerESP:GetBoundingBox(Parts)
	local viewportSize = Camera.ViewportSize
	local screenWidth, screenHeight = viewportSize.X, viewportSize.Y
	local min_x, max_x = math.huge, -math.huge
	local min_y, max_y = math.huge, -math.huge
	local foundInFront = false

	for _, Part in ipairs(Parts) do
		if Part:IsA("BasePart") then
			local screenPoint = Camera:WorldToScreenPoint(Part.Position)
			if screenPoint.Z > 0 then
				foundInFront = true

				local x, y = screenPoint.X, screenPoint.Y
				min_x = math.min(min_x, x)
				max_x = math.max(max_x, x)
				min_y = math.min(min_y, y)
				max_y = math.max(max_y, y)
			end
		end
	end

	if not foundInFront then
		return nil
	end

	local w, h = max_x - min_x, max_y - min_y

	local pad_x, pad_y = w * 0.23, h * 0.17
	local final_x = min_x - pad_x
	local final_y = min_y - pad_y
	local final_w = w + (pad_x * 2)
	local final_h = h + (pad_y * 2)

	if final_w < 10 or final_h < 20 then
		local center_x = (min_x + max_x) / 2
		local center_y = (min_y + max_y) / 2
		final_x = center_x - 30
		final_y = center_y - 50
		final_w = 60
		final_h = 100
	end

	final_x = math.max(0, math.min(final_x, screenWidth - final_w))
	final_y = math.max(0, math.min(final_y, screenHeight - final_h))

	return {
		X = final_x,
		Y = final_y,
		W = final_w,
		H = final_h,
	}
end

return PlayerESP
