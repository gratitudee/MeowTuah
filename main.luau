local Repo = "https://raw.githubusercontent.com/gratitudee/MeowTuah/main/"

getgenv().LoadModule = function(ModulePath)
	local URL = Repo .. ModulePath
	local Success, Result = pcall(function(...)
		return loadstring(game:HttpGet(URL, true))()
	end)

	if not Success then
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

return function(Override)
	getgenv().MeowTuah = {
		Library = LoadModule("packages/UI.lua"),
		SaveManager = LoadModule("packages/SaveManager.lua"),
		ThemeManager = LoadModule("packages/ThemeManager.lua"),
	}

	if Override then
		print("Ran With Override")
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
end
