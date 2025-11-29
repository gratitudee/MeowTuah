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
		["Player ESP"] = MainWindow:AddTab("Visuals"),
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
	local VisualsLeftGroup = Tabs["Player ESP"]:AddLeftGroupbox("Visuals | Players")
	local VisualsRightGroup = Tabs["Player ESP"]:AddRightGroupbox("Trinkets")

	-- Movement Stuff

	-- Callback Stuff
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
	MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })
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
