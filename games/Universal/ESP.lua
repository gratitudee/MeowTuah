local Services = require("../../core/Services")
local Utility = require("../../core/Utility")

local Feature = {
	Settings = {
		Enabled = false,
		TeamCheck = false,
		VisibleCheck = false,
		ShowHidden = false,
		ShowLocal = true,
		HiddenColor = { Color = Color3.fromRGB(82, 80, 80), Alpha = 0.5 },

		ESPElements = {
			["Name"] = {
				State = false,
				Color = Color3.fromRGB(255, 255, 255),
				Alpha = 0,
			},
			["Distance"] = {
				State = false,
				Color = Color3.fromRGB(255, 255, 255),
				Alpha = 0,
			},
			["Box"] = {
				State = false,
				Color = Color3.fromRGB(255, 255, 255),
				Alpha = 0,
			},
			["Box Fill"] = {
				State = false,
				Color = Color3.fromRGB(255, 255, 255),
				Alpha = 0,
			},
			["Health Text"] = {
				State = false,
				Color = Color3.fromRGB(255, 255, 255),
				Alpha = 0,
			},
			["Skeleton"] = {
				State = false,
				Color = Color3.fromRGB(255, 255, 255),
				Alpha = 0,
			},
		},
		MaxDistance = {},
		WhitelistedTeams = {},
	},
	Connections = {},
}

-- Private

-- Public Methods
function Feature:SetEnabled(state)
	Feature.Settings.Enabled = state
end

function Feature:SetESPTypes(table)
	Feature.Settings.ESPElements = table
end

function Feature:Initialise() end

function Feature:Cleanup() end
