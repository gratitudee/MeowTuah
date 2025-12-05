local Base = "games/GenericTycoonGame/Features"
local Automation = LoadModule(`{Base}/Automation.luau`)

return function(self)
	local Library = MeowTuah.Library
	local SaveManager = MeowTuah.SaveManager
	local ThemeManager = MeowTuah.ThemeManager
	local Services, Utility = MeowTuah.Services, MeowTuah.Utility

	local RunService = Services.RunService
	local Heartbeat = Utility.index(RunService, "Heartbeat")

	local MainWindow = Library:CreateWindow({
		Title = `{self.Name} | MEOW TUAH`,
		Center = true,
		AutoShow = true,
		MenuFadeTime = 0.2,
	})

	local Tabs = {
		Main = MainWindow:AddTab("Automation"),
		Settings = MainWindow:AddTab("Settings"),
	}

	local AutomationLeft = Tabs.Main:AddLeftGroupbox("Automation")

	AutomationLeft:AddToggle("AutoBuyButtons", {
		Text = "Auto Buy Buttons",
		Default = false,
		Tooltip = "Automatically buys the tycoon buttons.",
	})

	AutomationLeft:AddToggle("AutoRebirth", {
		Text = "Auto Rebirth",
		Default = false,
		Tooltip = "Automatically rebirths for you.",
	})

	AutomationLeft:AddToggle("AutoAscend", {
		Text = "Auto Ascend",
		Default = false,
		Tooltip = "Automatically ascends for you.",
	})

	AutomationLeft:AddToggle("AutoTycoonManager", {
		Text = "Auto Tycoon Manager",
		Default = false,
		Tooltip = "Automatically chooses the best tycoon manager option.",
	})

	Toggles.AutoBuyButtons:OnChanged(function()
		Automation.Flags.AutoBuyButtons = Toggles.AutoBuyButtons.Value
	end)

	Toggles.AutoRebirth:OnChanged(function()
		Automation.Flags.AutoRebirth = Toggles.AutoRebirth.Value
	end)

	Toggles.AutoAscend:OnChanged(function()
		Automation.Flags.AutoAscend = Toggles.AutoAscend.Value
	end)

	Toggles.AutoTycoonManager:OnChanged(function()
		Automation.Flags.AutoTycoonManager = Toggles.AutoTycoonManager.Value
	end)

	Automation:Start()

	local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
	MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
		Default = "Z",
		NoUI = true,
		Text = "Menu keybind",
	})
	Library.ToggleKeybind = Options.MenuKeybind

	MenuGroup:AddDivider()

	MenuGroup:AddToggle("KeybindListToggle", {
		Text = "Show Keybinds",
		Default = false,
		Tooltip = "Shows the keybind frame.",
		Callback = function(Value)
			Library.KeybindFrame.Visible = Value
		end,
	})

	MenuGroup:AddToggle("WatermarkToggle", {
		Text = "Show Watermark",
		Default = false,
		Tooltip = "Shows the watermark.",
		Callback = function(Value)
			Library:SetWatermarkVisibility(Value)
		end,
	})

	MenuGroup:AddDivider()

	MenuGroup:AddButton("Unload", function()
		Library:Unload()
	end)

	SaveManager:SetLibrary(Library)
	ThemeManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetFolder(`MeowTuah/{self.Name}`)
	ThemeManager:SetFolder("MeowTuah")
	SaveManager:BuildConfigSection(Tabs.Settings)
	ThemeManager:ApplyToTab(Tabs.Settings)
	SaveManager:LoadAutoloadConfig()

	local FrameTimer = tick()
	local FrameCounter = 0
	local FPS = 67
	local WatermarkHeartbeat = Heartbeat:Connect(function(a0: number)
		if not Toggles.WatermarkToggle.Value then
			return
		end

		FrameCounter += 1

		if (tick() - FrameTimer) >= 1 then
			FPS = FrameCounter
			FrameTimer = tick()
			FrameCounter = 0
		end

		Library:SetWatermark(`MEOW TUAH | {self.Name} | {FPS}FPS`)
	end)

	Library:OnUnload(function()
		WatermarkHeartbeat:Disconnect()
		Automation:Stop()
		Library.Unloaded = true
	end)
end
