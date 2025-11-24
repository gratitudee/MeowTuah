local UI = require("../core/UI")
local SaveManager = require("../core/SaveManager")
local ThemeManager = require("../core/ThemeManager")

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
