local MeowTuah = {
	VerbosePrinting = false,
	SupportedGames = {
		[1] = "cg-2",
	},
	CurrentGame = nil,
	Modules = {},
}

getgenv().MeowTuah = MeowTuah
MeowTuah.Repo = "https://raw.githubusercontent.com/gratitudee/meow-tuah/main/"

-- Utils
function MeowTuah:Print(Message, Level)
	if not MeowTuah.VerbosePrinting then
		return
	end

	local Executor = identifyexecutor()
	local Function = Executor == "Zenith" and printconsole or print
	Function(`[MEOW TUAH {Level}] - {Message}`)
end

function MeowTuah:SafeCall(identifier, func, ...)
	local success, result = pcall(func, ...)
	if not success then
		MeowTuah:Print(`{identifier} Failed: {result}`, "WARNING")
	end
	return success and result
end

function MeowTuah:LoadModule(ModulePath)
	local URL = MeowTuah.Repo .. ModulePath
	local Success, Result = MeowTuah:SafeCall(ModulePath, function(...)
		return loadstring(game:HttpGet(URL, true))()
	end)

	if not Success then
		MeowTuah:Print(`Failed to load {ModulePath}`, "CRITICAL")
		return nil
	end

	return Result
end

-- Main
function MeowTuah:ReturnCurrentGame()
	return MeowTuah.SupportedGames[game.PlaceId]
end

function MeowTuah:Initialise()
	if getgenv().MeowTuahLoaded then
		MeowTuah:Print("Already Loaded", "RUNTIME EXIT")
		return
	end

	local GameName = MeowTuah:ReturnCurrentGame()
	if not GameName then
		MeowTuah:Print(
			`Couldn't find supported game for {game.PlaceId} - defaulting to universal mode.`,
			"GAME NOT FOUND"
		)
	end

	MeowTuah.Modules.UI = MeowTuah:LoadModule("core/UI.lua")
	MeowTuah.Modules.Utility = MeowTuah:LoadModule("core/Utility.lua")
	MeowTuah.Modules.ThemeManager = MeowTuah:LoadModule("core/ThemeManager.lua")
	MeowTuah.Modules.SaveManager = MeowTuah:LoadModule("core/SaveManager.lua")

	if not GameName then
		GameName = "Universal"
	end

	local GameModule = MeowTuah:LoadModule(`games/{GameName}/init.lua`)
	if GameModule then
		GameModule:Initialise()
		MeowTuah.CurrentGame = GameName
		getgenv().MeowTuahLoaded = true
		return
	end

	MeowTuah:Print(`If you're seeing this I suck or something like that`, "SUPER DUPER CRAZY CRITICAL")
end

function MeowTuah:Unload()
	if MeowTuah.CurrentGame then
		local GameModule = MeowTuah:LoadModule(`games/{MeowTuah.CurrentGame}/init.lua`)
		if GameModule then
			GameModule:Cleanup()
		end
	end

	getgenv().MeowTuahLoaded = false
	MeowTuah.CurrentGame = nil
end

MeowTuah:Initialise()
return MeowTuah
