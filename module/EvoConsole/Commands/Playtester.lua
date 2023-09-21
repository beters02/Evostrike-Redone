local Players = game:GetService("Players")
local GamemodeService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("GamemodeService"))

local Commands = {}

Commands.Play = {
	Description = "Play a Playtester version of the game.",
	Public = false,

	Function = function(self, player, mapName, players)
        if not mapName then
            self:Error("Invalid command usage! Usage: play {mapName} .. Ex: play unstable")
            return
        end

		if string.lower(mapName) ~= "unstable" then
            self:Error("Invalid map! Available maps: unstable")
			return
		end

        local telePlayers = {player}
        local teleMult = false
        if players then
            if Players:FindFirstChild(players) then
                telePlayers = {Players[players], player}
                teleMult = true
            end
        end

		local success, err = game:GetService("ReplicatedStorage").Modules.EvoConsole.Objects.Bridge:InvokeServer("MapCommand", mapName, "Range", telePlayers)
		if not success then warn(err) return end
        if teleMult then self:Print("Teleporting multiple players!") else self:Print("Teleporting single player!") end
		return true
	end
}

Commands.Gamemode = {
	Description = "Set the gamemode. Only works if the current gamemode is Range or was changed from Range.",
	Public = false,
	
	Function = function(self, _, gamemodeName)
		GamemodeService:ChangeGamemode(gamemodeName)
		--game:GetService("ReplicatedStorage").gamemode.remote.Set:FireServer(gamemodeName, "playtester")
	end
}

return Commands