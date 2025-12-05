local Base = "games/GenericTycoonGame/Features"
local Automation = LoadModule(`{Base}/Automation.luau`)
local Exploits = LoadModule(`{Base}/Exploits.luau`)

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
	local ExploitsRight = Tabs.Main:AddRightGroupbox("Exploits")

	AutomationLeft:AddToggle("AutoBuyButtons", {
		Text = "Auto Buy Buttons",
		Default = false,
		Tooltip = "Automatically buys the tycoon buttons.",
	})

	AutomationLeft:AddDropdown("PurchasingOptions", {
		Values = { "Ignore Tokens", "Low Priority Blue Buttons", "Rapid Buy (Overrides All)" },
		Default = 1,
		Multi = true,

		Text = "Purchasing Options",
		Tooltip = "Modify how the script finds buttons to buy.",
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

	AutomationLeft:AddToggle("AutoGetBerry", {
		Text = "Auto Collect Berries",
		Default = false,
		Tooltip = "Automatically tweens towards berries and collects them.",
	})

	AutomationLeft:AddSlider("AutoGetBerryTweenSpeed", {
		Text = "Auto Collect Berry Speed",
		Default = 100,
		Min = 1,
		Max = 500,
		Rounding = 1,
		Compact = false,
	})

	ExploitsRight:AddToggle("InstantOres", {
		Text = "[?] Instant Ores",
		Default = false,
		Tooltip = "Teleports your ores to the collector.",
	})

	ExploitsRight:AddToggle("GrowableAura", {
		Text = "[?] Growable Aura",
		Default = false,
		Tooltip = "Collects growables automatically.",
	})

	Toggles.AutoBuyButtons:OnChanged(function()
		Automation.Flags.AutoBuyButtons = Toggles.AutoBuyButtons.Value
	end)

	Options.PurchasingOptions:OnChanged(function()
		for flag, _ in pairs(Automation.Flags.AutoBuyButtonPreferences) do
			Automation.Flags.AutoBuyButtonPreferences[flag] = Options.PurchasingOptions.Value[flag] == true
		end
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

	Toggles.AutoGetBerry:OnChanged(function()
		Automation.Flags.AutoGetBerry = Toggles.AutoGetBerry.Value
	end)

	Options.AutoGetBerryTweenSpeed:OnChanged(function()
		Automation.Flags.AutoGetBerryOptions["Tween Speed"] = Options.AutoGetBerryTweenSpeed.Value
	end)

	Toggles.InstantOres:OnChanged(function()
		Exploits.Flags.InstantOres = Toggles.InstantOres.Value
	end)

	Toggles.GrowableAura:OnChanged(function()
		Exploits.Flags.GrowableAura = Toggles.GrowableAura.Value
	end)

	Automation:Start()
	Exploits:Start()

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
		Exploits:Stop()
		Library.Unloaded = true
	end)
end
