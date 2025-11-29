local Trinket = {
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
	},
}

function Trinket:Start() end

function Trinket:Stop() end

return Trinket
