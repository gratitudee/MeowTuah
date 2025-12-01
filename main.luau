local Repo = "https://raw.githubusercontent.com/gratitudee/MeowTuah/main/"

getgenv().LoadModule = function(ModulePath)
	local URL = Repo .. ModulePath
	local Success, Result = pcall(function(...)
		return loadstring(game:HttpGet(URL, true))()
	end)

	if not Success then
		print(`[LOADMODULE]: {Result}`)
		return nil
	end

	return Result
end

-- vars
local games = {
	{
		Name = "Universal",
		Load = LoadModule("games/Universal/init.luau"),
	},
	{
		Name = "Cult Game 2",
		Load = LoadModule("games/CG2/init.luau"),
	},
}

local OriginalFindService = game.FindService
local function Hook(cb)
	if getgenv().HookedFindService then
		cb()
		return
	end

	getgenv().HookedFindService = true
	hookfunction(OriginalFindService, function(self, Service)
		if Service == "VirtualUser" or Service == "VirtualInputManager" or Service == "UGCValidationService" then
			return false
		end
		return OriginalFindService(self, Service)
	end)
	task.delay(1, cb)
end

return function(Override)
	Hook(function()
		getgenv().MeowTuah = {
			Library = LoadModule("packages/UI.lua"),
			SaveManager = LoadModule("packages/SaveManager.lua"),
			ThemeManager = LoadModule("packages/ThemeManager.lua"),
			Utility = LoadModule("core/Utility.lua"),
			Services = LoadModule("core/Services.lua"),
		}

		if Override then
			for _, module in pairs(games) do
				if module.Name == Override then
					return module.Load(module)
				end
			end
		end

		for _, module in pairs(games) do
			if module.UniverseId and module.UniverseId == game.GameId then
				return module.Load(module)
			end
		end

		return games[1].Load(games[1])
	end)
end
