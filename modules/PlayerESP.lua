local Services, Utility = LoadModule("core/Services.lua"), LoadModule("core/Utility.lua")
local Workspace = Services.Workspace
local CoreGui = gethui and gethui() or Services.CoreGui

-- Variables
local Camera = Utility.index(Workspace, "CurrentCamera")
local FindFirstChild = Utility.FindFirstChild
local GetDescendants = Utility.GetDescendants
local WorldToViewportPoint = Utility.index(Camera, "WorldToViewportPoint")
local CubeCorners = {
	Vector3.new(0, -1, -1),
	Vector3.new(0, -1, 1),
	Vector3.new(0, 1, -1),
	Vector3.new(0, 1, 1),
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

function PlayerESP:DrawHighlight()
	local Highlight = Instance.new("Highlight")
	Highlight.Enabled = false
	Highlight.Parent = CoreGui

	return {
		Highlight = Highlight,

		SetVisible = function(self, state)
			self.Highlight.Enabled = state
		end,

		SetFillProperties = function(self, Color, Transparency)
			self.Highlight.FillColor = Color
			self.Highlight.FillTransparency = Transparency
		end,

		SetOutlineProperties = function(self, Color, Transparency)
			self.Highlight.OutlineColor = Color
			self.Highlight.OutlineTransparency = Transparency
		end,

		SetCharacter = function(self, Character)
			self.Highlight.Adornee = Character
		end,

		Remove = function(self)
			self.Highlight:Destroy()
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

	local Width = MaxX - MinX
	local Height = MaxY - MinY
	local PadX = Width * 0.23
	local PadY = Height * 0.17

	return {
		X = MinX - PadX,
		Y = MinY - PadY,
		W = Width + PadX * 2,
		H = Height + PadY * 2,
	}
end

function PlayerESP:DrawViewportXRay()
	local ScreenUI = FindFirstChild(CoreGui, "VPXray")
	if not ScreenUI then
		ScreenUI = Instance.new("ScreenGui")
		ScreenUI.Name = "VPXray"
		ScreenUI.Parent = CoreGui
		ScreenUI.IgnoreGuiInset = true
		ScreenUI.ResetOnSpawn = false
		ScreenUI.DisplayOrder = math.huge
	end

	local ViewportFrame = FindFirstChild(ScreenUI, "VPXrayFrame")
	if not ViewportFrame then
		ViewportFrame = Instance.new("ViewportFrame")
		ViewportFrame.Name = "VPXrayFrame"
		ViewportFrame.Size = UDim2.fromScale(1, 1)
		ViewportFrame.BackgroundTransparency = 1
		ViewportFrame.LightDirection = Vector3.new(-1, -1, -1)
		ViewportFrame.Ambient = Color3.fromRGB(120, 120, 120)
		ViewportFrame.Parent = ScreenUI
	end

	local ViewportCamera = FindFirstChild(ViewportFrame, "VPCamera")
	if not ViewportCamera then
		ViewportCamera = Instance.new("Camera")
		ViewportCamera.Name = "VPCamera"
		ViewportCamera.FieldOfView = Camera.FieldOfView
		ViewportCamera.Parent = ViewportFrame
		ViewportFrame.CurrentCamera = ViewportCamera
	end

	return {
		ScreenUI = ScreenUI,
		ViewportFrame = ViewportFrame,
		ViewportCamera = ViewportCamera,
		ViewportModel = nil,
		LastCharacter = nil,
		RayIgnore = {},

		SetVisible = function(self, state)
			self.ScreenUI.Enabled = state
			if not state and self.ViewportModel then
				self:Remove()
			end
		end,

		SetRayIgnore = function(self, object)
			self.RayIgnore[1] = object
		end,

		Update = function(self, dictionary)
			if not self.ScreenUI.Enabled then
				return
			end

			self.ViewportCamera.CFrame = Camera.CFrame

			local Character = dictionary.Character
			if not Character then
				if self.ViewportModel then
					self:Remove()
				end
				return
			end

			if Character ~= self.LastCharacter then
				self:__RefreshViewportModel(Character)
				print("Refreshed")
				self.LastCharacter = Character
			end

			if not self.ViewportModel then
				self:__GetNewViewportModel(Character)
			end

			local visible = self:__IsVisible(Character)
			self:SetTransparencyBasedOnVisibility(visible)
			if not visible then
				self:__UpdateCloneCFrames(Character)
			end
		end,

		__IsVisible = function(self, character)
			if not character then
				return false
			end

			local hrp = FindFirstChild(character, "HumanoidRootPart")
			if not hrp then
				return false
			end

			local pos = hrp.Position
			local camPos = Camera.CFrame.Position

			local _, onScreen = WorldToScreen(pos)
			if not onScreen then
				print(`{character.nAME} is not onscreen.`)
				return false
			end

			local distance = (pos - camPos).Magnitude
			if distance > 250 then
				return false
			end

			local direction = (pos - camPos)
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = self.RayIgnore
			params.FilterType = Enum.RaycastFilterType.Exclude

			local result = Workspace:Raycast(camPos, direction, params)
			print(result.Instance:IsDescendantOf(character))
			return not result or result.Instance:IsDescendantOf(character)
		end,

		SetTransparencyBasedOnVisibility = function(self, visible)
			if not self.ViewportModel then
				return
			end

			for _, part in pairs(self.ViewportModel:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
					part.LocalTransparencyModifier = visible and 1 or 0
				end
			end
		end,

		__UpdateCloneCFrames = function(self, character)
			if not character or not self.ViewportModel then
				return
			end

			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					local clonePart = self.ViewportModel:FindFirstChild(part.Name, true)
					if clonePart and clonePart:IsA("BasePart") then
						clonePart.CFrame = part.CFrame
					end
				end
			end

			for _, obj in pairs(character:GetChildren()) do
				if obj:IsA("Accessory") or obj:IsA("Tool") then
					local cloneObj = self.ViewportModel:FindFirstChild(obj.Name)
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
						self:__RefreshViewportModel(character)
						return
					end
				end
			end
		end,

		__GetNewViewportModel = function(self, character)
			if self.ViewportModel then
				return self.ViewportModel
			end

			if character and character.PrimaryPart then
				character.Archivable = true
				self.ViewportModel = character:Clone()
				character.Archivable = false

				for _, object in pairs(self.ViewportModel:GetDescendants()) do
					if object:IsA("BasePart") then
						object.Anchored = true
						object.CanTouch = false
						object.CanQuery = false
						object.CastShadow = false
						object.Massless = true
					elseif object:IsA("LocalScript") or object:IsA("Script") or object:IsA("ModuleScript") then
						object:Destroy()
					end
				end

				self.ViewportModel.Parent = self.ViewportFrame
			end

			return self.ViewportModel
		end,

		__RefreshViewportModel = function(self, character)
			if self.ViewportModel then
				self.ViewportModel:Destroy()
				self.ViewportModel = nil
			end
			self:__GetNewViewportModel(character)
		end,

		Remove = function(self)
			if self.ViewportModel then
				self.ViewportModel:Destroy()
				self.ViewportModel = nil
			end

			self.LastCharacter = nil
		end,
	}
end

return PlayerESP
