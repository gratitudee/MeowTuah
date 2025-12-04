-- Utility Module

local INV_PHI = (math.sqrt(5) - 1) / 2
local MAX_COLOR_ATTEMPTS = 100
local MAX_USED_HUES = 20

LPH_NO_VIRTUALIZE = function(f)
	return f
end

local animator = Instance.new("Animator")
local ghostanim = Instance.new("Animation")
ghostanim.AnimationId = "rbxassetid://0"
local ghosttrack = animator:LoadAnimation(ghostanim)

local Utils = {}
local toggledFunctions = {}
local usedHues = {}
local colorCache = {}

local rawDatamodel = getrawmetatable and getrawmetatable(game)
	or {
		__index = LPH_NO_VIRTUALIZE(function(self, Index)
			return self[Index]
		end),
		__newindex = LPH_NO_VIRTUALIZE(function(self, Index, Value)
			self[Index] = Value
		end),
	}

-- Cached game methods
Utils.index = rawDatamodel.__index
Utils.newindex = rawDatamodel.__newindex
Utils._GetService = Utils.index(game, "GetService")
Utils.GetChildren = Utils.index(game, "GetChildren")
Utils.GetDescendants = Utils.index(game, "GetDescendants")
Utils.FindFirstChild = Utils.index(game, "FindFirstChild")
Utils.FindFirstChildOfClass = Utils.index(game, "FindFirstChildOfClass")
Utils.FindFirstChildWhichIsA = Utils.index(game, "FindFirstChildWhichIsA")
Utils.WaitForChild = Utils.index(game, "WaitForChild")
Utils.GetMarkerReachedSignal = Utils.index(ghosttrack, "GetMarkerReachedSignal")

function Utils.GetService(service: string)
	local result = Utils._GetService(game, service)
	return cloneref and cloneref(result) or result
end

function Utils.CreateSignal()
	local signal = {
		_callbacks = {},
	}

	function signal:Connect(callback)
		table.insert(self._callbacks, callback)
		return {
			Disconnect = function()
				for i, cb in pairs(self._callbacks) do
					if cb == callback then
						table.remove(self._callbacks, i)
						break
					end
				end
			end,
		}
	end

	function signal:Fire(...)
		for _, callback in pairs(self._callbacks) do
			task.spawn(callback, ...)
		end
	end

	return signal
end

function Utils.generateUniqueColor(filterName)
	if filterName and colorCache[filterName] then
		return colorCache[filterName]
	end

	local hue = (math.random() + INV_PHI) % 1

	for attempt = 1, MAX_COLOR_ATTEMPTS do
		local unique = true

		for _, usedHue in ipairs(usedHues) do
			if math.abs(hue - usedHue) < 0.1 then
				unique = false
				break
			end
		end

		if unique then
			break
		end

		hue = (hue + INV_PHI) % 1

		if attempt == MAX_COLOR_ATTEMPTS then
			table.clear(usedHues)
		end
	end

	table.insert(usedHues, hue)

	if #usedHues > MAX_USED_HUES then
		table.remove(usedHues, 1)
	end

	local saturation, value = 0.8, 0.9
	local i, f = math.floor(hue * 6), hue * 6 % 1
	local p, q, t = value * (1 - saturation), value * (1 - f * saturation), value * (1 - (1 - f) * saturation)

	local r, g, b =
		(i % 6 == 0 and value or i % 6 == 1 and q or i % 6 == 2 and p or i % 6 == 3 and p or i % 6 == 4 and t or value),
		(i % 6 == 0 and t or i % 6 == 1 and value or i % 6 == 2 and value or i % 6 == 3 and q or i % 6 == 4 and p or p),
		(i % 6 == 0 and p or i % 6 == 1 and p or i % 6 == 2 and t or i % 6 == 3 and value or i % 6 == 4 and value or q)

	local color = Color3.new(r, g, b)

	if filterName then
		colorCache[filterName] = color
	end

	return color
end

-- Player utilities
function Utils.GetPlayer()
	local success, result = pcall(function()
		return Utils.GetService("Players")
	end)

	return success and Utils.index(result, "LocalPlayer")
end

function Utils.GetCharacter(player)
	local success, result = pcall(function()
		return player and Utils.index(player, "Character")
	end)

	return success and result
end

function Utils.GetHumanoid(player)
	local success, result = pcall(function()
		local character = Utils.GetCharacter(player)
		return character and Utils.FindFirstChildOfClass(character, "Humanoid")
	end)

	return success and result
end

return Utils
