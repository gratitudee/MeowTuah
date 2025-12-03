local Repo = "https://raw.githubusercontent.com/gratitudee/MeowTuah/main/"

getgenv().LoadModule = function(ModulePath)
	local URL = Repo .. ModulePath
	local Success, Result = pcall(function(...)
		return loadstring(game:HttpGet(URL, true))()
	end)

	if not Success then
		print(`[{ModulePath}]: {Result}`)
		return nil
	end

	return Result
end

local OriginalFindService = game.FindService
local function Hook(cb)
	if getgenv().HookedFindService then
		cb()
		return
	end

	getgenv().HookedFindService = true
	hookfunction(game.FindService, function(self, Service)
		if Service == "VirtualUser" or Service == "VirtualInputManager" or Service == "UGCValidationService" then
			return false
		end

		return OriginalFindService(self, Service)
	end)
	cb()
end

return function(Options)
	Hook(function()
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

		getgenv().MeowTuah = {
			Library = LoadModule("packages/UI.lua"),
			SaveManager = LoadModule("packages/SaveManager.lua"),
			ThemeManager = LoadModule("packages/ThemeManager.lua"),
			Utility = LoadModule("core/Utility.lua"),
			Services = LoadModule("core/Services.lua"),
			Print = function(Message)
				if Options.SCRIPT_DBG then
					print(`[MEOW TUAH]: {Message}`)
				end
			end,

			SafeCall = function(self, ToCall)
				local s, e = pcall(ToCall)
				if not s then
					self:Print(e)
				end
			end,
		}

		if Options.Override then
			for _, module in pairs(games) do
				if module.Name == Options.Override then
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
