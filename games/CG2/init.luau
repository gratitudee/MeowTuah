local Base = "games/CG2/Features"
local AutoParry, Movement, PlayerESP, Trinket =
	LoadModule(`{Base}/AutoParry.luau`),
	LoadModule(`{Base}/Movement.luau`),
	LoadModule(`{Base}/PlayerESP.luau`),
	LoadModule(`{Base}/Trinket.luau`)

return function(self)
	local Library, SaveManager, ThemeManager = MeowTuah.Library, MeowTuah.SaveManager, MeowTuah.ThemeManager
	local MainWindow = Library:CreateWindow({
		Title = `{self.Name} | MEOW TUAH`,
		Center = true,
		AutoShow = true,
		MenuFadeTime = 0.2,
	})

	local Tabs = {
		["Auto Parry"] = MainWindow:AddTab("Auto Parry"),
		["Visuals"] = MainWindow:AddTab("Visuals"),
		["Movement"] = MainWindow:AddTab("Movement"),
		["Settings"] = MainWindow:AddTab("Settings"),
	}

	-- Auto Parry Stuff
	local AutoParryLeftGroup = Tabs["Auto Parry"]:AddLeftGroupbox("Auto Parry Main")
	AutoParryLeftGroup:AddLabel("Enable Auto Parry"):AddKeyPicker("AutoParryKeyPicker", {
		Default = "E",
		SyncToggleState = false,
		Mode = "Toggle",
		Text = "Auto Parry",
		NoUI = false,
	})

	AutoParryLeftGroup:AddSlider("AutoParryMaxDistance", {
		Text = "Auto Parry Max Distance",
		Default = 10,
		Min = 1,
		Max = 25,
		Rounding = 1,
		Compact = false,
	})

	-- Visual Stuff
	local VisualsLeftGroup = Tabs["Visuals"]:AddLeftGroupbox("Player Visuals")

	VisualsLeftGroup:AddToggle("PlayerESPEnabled", {
		Text = "Enable",
		Default = false,
		Tooltip = "Master Switch For The Player ESP.",
	})

	VisualsLeftGroup:AddToggle("PlayerBoxEnabled", {
		Text = "Box",
		Default = false,
		Tooltip = "Enables Player Box ESP",
	}):AddColorPicker("PlayerBoxColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Box Color",
		Transparency = 0,
	})

	VisualsLeftGroup:AddToggle("PlayerFilledBoxEnabled", {
		Text = "FilledBox",
		Default = false,
		Tooltip = "Enables Player Filled Box ESP",
	}):AddColorPicker("PlayerFilledBoxColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Filled Box Color",
		Transparency = 0.85,
	})

	VisualsLeftGroup:AddToggle("PlayerNameEnabled", {
		Text = "Name",
		Default = false,
		Tooltip = "Enables Player Name ESP",
	}):AddColorPicker("PlayerNameColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Name Color",
		Transparency = 0,
	})

	VisualsLeftGroup:AddToggle("PlayerDistanceEnabled", {
		Text = "Distance",
		Default = false,
		Tooltip = "Enables Player Distance ESP",
	}):AddColorPicker("PlayerDistanceColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Distance Color",
		Transparency = 0,
	})

	VisualsLeftGroup:AddToggle("PlayerHealthEnabled", {
		Text = "Health",
		Default = false,
		Tooltip = "Enables Player Health Bar ESP",
	})

	VisualsLeftGroup:AddToggle("PlayerBountyEnabled", {
		Text = "Bounty",
		Default = false,
		Tooltip = "Enables Player Bounty ESP",
	}):AddColorPicker("PlayerBountyColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Bounty Color",
		Transparency = 0,
	})

	-- Trinket Stuff
	local TrinketTabBox = Tabs["Visuals"]:AddRightTabbox()
	local TrinketVisualsTab = TrinketTabBox:AddTab("Trinket Visuals")
	local TrinketAutograbTab = TrinketTabBox:AddTab("Trinket Auto Grab")

	TrinketVisualsTab:AddToggle("TrinketESPEnabled", {
		Text = "Enable",
		Default = false,
		Tooltip = "Enables Trinket ESP",
	})

	TrinketVisualsTab:AddSlider("TrinketESPMaxDistance", {
		Text = "Trinket ESP Max Distance",
		Default = 1000,
		Min = 1,
		Max = 1500,
		Rounding = 1,
		Compact = false,
	})

	TrinketVisualsTab:AddToggle("TrinketNameEnabled", {
		Text = "Name",
		Default = false,
		Tooltip = "Enables Trinket Name ESP",
	}):AddColorPicker("TrinketNameColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Name Color",
		Transparency = 0,
	})

	TrinketVisualsTab:AddToggle("TrinketDistanceEnabled", {
		Text = "Distance",
		Default = false,
		Tooltip = "Enables Trinket Distance ESP",
	}):AddColorPicker("TrinketDistanceColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Distance Color",
		Transparency = 0,
	})

	TrinketVisualsTab:AddToggle("TrinketValueEnabled", {
		Text = "Value",
		Default = false,
		Tooltip = "Enables Trinket Value ESP",
	}):AddColorPicker("TrinketValueColor", {
		Default = Color3.new(0, 1, 0),
		Title = "Value Color",
		Transparency = 0,
	})

	TrinketAutograbTab:AddToggle("TrinketAutograbEnabled", {
		Text = "Enable",
		Default = false,
		Tooltip = "Enables Trinket Auto Grabbing.",
	})

	-- Movement Stuff

	-- Callback Stuff

	-- Auto Parry Callbacks
	Options.AutoParryKeyPicker:OnClick(function(Value)
		AutoParry.Enabled = Value
	end)

	task.spawn(function()
		while true do
			task.wait(0.1)
			AutoParry.Enabled = Options.AutoParryKeyPicker:GetState()

			if Library.Unloaded then
				break
			end
		end
	end)

	Options.AutoParryMaxDistance:OnChanged(function()
		AutoParry.MaxDistance = Options.AutoParryMaxDistance.Value
	end)

	-- Visual Callbacks
	Toggles.PlayerESPEnabled:OnChanged(function()
		PlayerESP.Enabled = Toggles.PlayerESPEnabled.Value
	end)

	Toggles.PlayerBoxEnabled:OnChanged(function()
		PlayerESP.Box.Enabled = Toggles.PlayerBoxEnabled.Value
	end)

	Options.PlayerBoxColor:OnChanged(function()
		PlayerESP.Box.Color = Options.PlayerBoxColor.Value
		PlayerESP.Box.Transparency = Options.PlayerBoxColor.Transparency
	end)

	Toggles.PlayerFilledBoxEnabled:OnChanged(function()
		PlayerESP.FilledBox.Enabled = Toggles.PlayerFilledBoxEnabled.Value
	end)

	Options.PlayerFilledBoxColor:OnChanged(function()
		PlayerESP.FilledBox.Color = Options.PlayerFilledBoxColor.Value
		PlayerESP.FilledBox.Transparency = Options.PlayerFilledBoxColor.Transparency
	end)

	Toggles.PlayerNameEnabled:OnChanged(function()
		PlayerESP.Name.Enabled = Toggles.PlayerNameEnabled.Value
	end)

	Options.PlayerNameColor:OnChanged(function()
		PlayerESP.Name.Color = Options.PlayerNameColor.Value
		PlayerESP.Name.Transparency = Options.PlayerNameColor.Transparency
	end)

	Toggles.PlayerDistanceEnabled:OnChanged(function()
		PlayerESP.Distance.Enabled = Toggles.PlayerDistanceEnabled.Value
	end)

	Options.PlayerDistanceColor:OnChanged(function()
		PlayerESP.Distance.Color = Options.PlayerDistanceColor.Value
		PlayerESP.Distance.Transparency = Options.PlayerDistanceColor.Transparency
	end)

	Toggles.PlayerHealthEnabled:OnChanged(function()
		PlayerESP.Health.Enabled = Toggles.PlayerHealthEnabled.Value
	end)

	Toggles.PlayerBountyEnabled:OnChanged(function()
		PlayerESP.Bounty.Enabled = Toggles.PlayerBountyEnabled.Value
	end)

	Options.PlayerBountyColor:OnChanged(function()
		PlayerESP.Bounty.Color = Options.PlayerBountyColor.Value
		PlayerESP.Bounty.Transparency = Options.PlayerBountyColor.Transparency
	end)

	-- Trinket Callbacks
	Toggles.TrinketESPEnabled:OnChanged(function()
		Trinket.ESP.Enabled = Toggles.TrinketESPEnabled.Value
	end)

	Options.TrinketESPMaxDistance:OnChanged(function()
		Trinket.ESP.MaxDistance = Options.TrinketESPMaxDistance.Value
	end)

	Toggles.TrinketNameEnabled:OnChanged(function()
		Trinket.ESP.Name.Enabled = Toggles.TrinketNameEnabled.Value
	end)

	Toggles.TrinketDistanceEnabled:OnChanged(function()
		Trinket.ESP.Distance.Enabled = Toggles.TrinketDistanceEnabled.Value
	end)

	Toggles.TrinketValueEnabled:OnChanged(function()
		Trinket.ESP.Value.Enabled = Toggles.TrinketValueEnabled.Value
	end)

	Toggles.TrinketAutograbEnabled:OnChanged(function()
		Trinket.AutoGrab.Enabled = Toggles.TrinketAutograbEnabled.Value
	end)

	Options.TrinketNameColor:OnChanged(function()
		Trinket.ESP.Name.Color = Options.TrinketNameColor.Value
		Trinket.ESP.Name.Transparency = Options.TrinketNameColor.Transparency
	end)

	Options.TrinketDistanceColor:OnChanged(function()
		Trinket.ESP.Distance.Color = Options.TrinketDistanceColor.Value
		Trinket.ESP.Distance.Transparency = Options.TrinketDistanceColor.Transparency
	end)

	Options.TrinketValueColor:OnChanged(function()
		Trinket.ESP.Value.Color = Options.TrinketValueColor.Value
		Trinket.ESP.Value.Transparency = Options.TrinketValueColor.Transparency
	end)

	-- Movement Callbacks

	-- Settings Stuff
	Library.KeybindFrame.Visible = true
	Library:OnUnload(function()
		AutoParry:Stop()
		Movement:Stop()
		PlayerESP:Stop()
		Trinket:Stop()
		Library.Unloaded = true
	end)

	local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
	MenuGroup:AddButton("Unload", function()
		Library:Unload()
	end)
	MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "Z", NoUI = true, Text = "Menu keybind" })
	Library.ToggleKeybind = Options.MenuKeybind

	-- M A N A G E R S . . .
	SaveManager:SetLibrary(Library)
	ThemeManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetFolder(`MeowTuah/{self.Name}`)
	ThemeManager:SetFolder("MeowTuah")
	SaveManager:BuildConfigSection(Tabs.Settings)
	ThemeManager:ApplyToTab(Tabs.Settings)
	SaveManager:LoadAutoloadConfig()
end
