<<<<<<< HEAD
local UI = MeowTuah.Modules.UI
local SaveManager = MeowTuah.Modules.SaveManager
local ThemeManager = MeowTuah.Modules.ThemeManager

=======
>>>>>>> e377b65a235665a9b8508a6156f3d826376e0671
local Game = {
	GameName = "TEMPLATE",
	Features = {},
	Toggles = {},
	Options = {},
}

function Game:Initialise() end

function Game:CreateUI()
	local Window = UI:CreateWindow({
		Title = `MEOW TUAH - {Game.GameName}`,
		Center = true,
		AutoShow = true,
		TabPadding = 8,
		MenuFadeTime = 0.2,
	})

	local SettingsTab = Window:AddTab("Settings")
	local LeftGroupBox = SettingsTab:AddLeftGroupbox("Groupbox")

	LeftGroupBox:AddLabel("Menu Bind")
		:AddKeyPicker("MenuKeybind", { Default = "Z", NoUI = true, Text = "Menu Keybind" })
	Library.ToggleKeybind = Options.MenuKeybind

	ThemeManager:SetLibrary(UI)
	ThemeManager:SetFolder("MeowTuah/Themes")
	ThemeManager:ApplyToTab(SettingsTab)

	SaveManager:SetLibrary(UI)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetFolder(`MeowTuah/Configs/{MeowTuah.CurrentGame}`)
	SaveManager:BuildConfigSection(SettingsTab)
	SaveManager:LoadAutoloadConfig()
end

function Game:CreateCallbacks() end

function Game:Cleanup() end

return Game
