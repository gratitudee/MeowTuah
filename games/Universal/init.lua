local UI = MeowTuah.Modules.UI
local SaveManager = MeowTuah.Modules.SaveManager
local ThemeManager = MeowTuah.Modules.ThemeManager

local Game = {
	GameName = "TEMPLATE",
	Features = {},
	Toggles = {},
	Options = {},
}

function Game:Initialise()
	Game:CreateUI()
end

function Game:CreateUI()
	local Window = UI:CreateWindow({
		Title = `MEOW TUAH - {Game.GameName}`,
		Center = true,
		AutoShow = true,
		TabPadding = 8,
		MenuFadeTime = 0.2,
	})

	local SettingsTab = Window:AddTab("Settings")
	local LeftGroupBox = SettingsTab:AddLeftGroupbox("Menu Interaction")

	LeftGroupBox:AddLabel("Menu Bind")
		:AddKeyPicker("MenuKeybind", { Default = "Z", NoUI = true, Text = "Menu Keybind" })
	Library.ToggleKeybind = Options.MenuKeybind

	LeftGroupBox:AddButton("Unload", function()
		MeowTuah:Unload()
		UI:Unload()
	end)

	UI:OnUnload(function() end)

	ThemeManager:SetLibrary(UI)
	ThemeManager:SetFolder(`MeowTuah/{Game.GameName}`)
	ThemeManager:ApplyToTab(SettingsTab)

	SaveManager:SetLibrary(UI)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetFolder(`MeowTuah/{Game.GameName}`)
	SaveManager:BuildConfigSection(SettingsTab)
	SaveManager:LoadAutoloadConfig()
end

function Game:CreateCallbacks() end

function Game:Cleanup() end

return Game
