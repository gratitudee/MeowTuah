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
		TabPadding = 8,
		MenuFadeTime = 0.2,
	})

	local Tabs = {
		["Auto Parry"] = MainWindow:AddTab("Auto Parry"),
		["Player ESP"] = MainWindow:AddTab("Player ESP"),
		["Trinkets"] = MainWindow:AddTab("Trinkets"),
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
	local VisualsLeftGroup = Tabs["Player ESP"]:AddLeftGroupbox("Visuals")

	-- Trinket Stuff
	local TrinketsLeftGroup = Tabs["Trinkets"]:AddLeftGroupbox("Trinket | ESP")
	local TrinketsRightGroup = Tabs["Trinkets"]:AddRightGroupbox("Trinket | Auto Grab")

	TrinketsLeftGroup:AddToggle("TrinketESPEnabled", {
		Text = "Enabled",
		Default = false,
		Tooltip = "Enables Trinket ESP",
	})

	TrinketsLeftGroup:AddSlider("TrinketESPMaxDistance", {
		Text = "Trinket ESP Max Distance",
		Default = 1000,
		Min = 1,
		Max = 1500,
		Rounding = 1,
		Compact = false,
	})

	TrinketsLeftGroup:AddToggle("TrinketNameEnabled", {
		Text = "Name",
		Default = false,
		Tooltip = "Enables Trinket Name ESP",
	}):AddColorPicker("TrinketNameColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Name Color",
		Transparency = 0,
	})

	TrinketsLeftGroup:AddToggle("TrinketDistanceEnabled", {
		Text = "Distance",
		Default = false,
		Tooltip = "Enables Trinket Distance ESP",
	}):AddColorPicker("TrinketDistanceColor", {
		Default = Color3.new(1, 1, 1),
		Title = "Distance Color",
		Transparency = 0,
	})

	TrinketsLeftGroup:AddToggle("TrinketValueEnabled", {
		Text = "Value",
		Default = false,
		Tooltip = "Enables Trinket Value ESP",
	}):AddColorPicker("TrinketValueColor", {
		Default = Color3.new(0, 1, 0),
		Title = "Value Color",
		Transparency = 0,
	})

	-- Movement Stuff

	-- Callback Stuff

	-- Auto Parry Callbacks
	for key, value in pairs(Options) do
		print(key, value)
	end

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

	-- Trinket Callbacks
	Options.TrinketESPEnabled:OnChanged(function()
		Trinket.ESP.Enabled = Options.TrinketESPEnabled.Value
	end)

	Options.TrinketESPMaxDistance:OnChanged(function()
		Trinket.ESP.MaxDistance = Options.TrinketESPMaxDistance.Value
	end)

	Options.TrinketNameEnabled:OnChanged(function()
		Trinket.ESP.Name.Enabled = Options.TrinketNameEnabled.Value
	end)

	Options.TrinketDistanceEnabled:OnChanged(function()
		Trinket.ESP.Distance.Enabled = Options.TrinketDistanceEnabled.Value
	end)

	Options.TrinketValueEnabled:OnChanged(function()
		Trinket.ESP.Value.Enabled = Options.TrinketValueEnabled.Value
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
