local Repo = "https://raw.githubusercontent.com/gratitudee/MeowTuah/main/"

getgenv().LoadModule = function(ModulePath)
	local URL = Repo .. ModulePath
	local Success, Result = pcall(function(...)
		return loadstring(game:HttpGet(URL, true))
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
		Load = LoadModule("games/Universal/file.luau"),
	},
	{
		Name = "Cult Game 2",
		Load = LoadModule("games/CG2/file.luau"),
	},
}

return function(Override)
	if Override then
		for _, module in pairs(games) do
			if game.Name == Override then
				return module:Load()
			end
		end
	end

	for _, module in pairs(games) do
		if module.UniverseId and module.UniverseId == game.GameId then
			return module:Load()
		end
	end

	return games[1]:Load()
end
