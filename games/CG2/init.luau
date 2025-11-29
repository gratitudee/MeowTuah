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

	AutoParry:Start()
	Movement:Start()
	Visuals:Start()
end
