local PlayerESP = {
	Enabled = false,

	Box = {
		Enabled = false,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
	},

	FilledBox = {
		Enabled = false,
		Color = Color3.new(1, 1, 1),
		Transparency = 0.85,
	},

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

	Health = {
		Enabled = false,
	},

	Bounty = {
		Enabled = false,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
	},
}

function PlayerESP:Start() end

function PlayerESP:Stop() end

return PlayerESP
