local Base = "games/CG2/Features"
local AutoParry, Movement, Visuals =
	LoadModule(`{Base}/AutoParry.luau`), LoadModule(`{Base}/Movement.luau`), LoadModule(`{Base}/Visuals.luau`)

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
		["AutoParry"] = MainWindow:AddTab("Auto Parry"),
		["Visuals"] = MainWindow:AddTab("Visuals"),
		["Movement"] = MainWindow:AddTab("Movement"),
		["Settings"] = MainWindow:AddTab("Settings"),
	}

	-- Auto Parry Stuff

	-- Visual Stuff

	-- Movement Stuff

	-- Callback Stuff

	-- Settings Stuff
	Library.KeybindFrame.Visible = true
	Library:OnUnload(function()
		AutoParry:Stop()
		Movement:Stop()
		Visuals:Stop()
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
