local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Types"))

local Commands = {}

Commands.place = {
    name = "place",
    vars = {
        mapName = {vartype = "string", required = true, index = 1},
        players = {vartype = "string", required = false, index = 2},
        gamemode = {vartype = "string", required = false, index = 3},
    },

    callback = function(console: Types.CConsole, mapName: string, players: string?, gamemode: string?)
        local varSuccess = console.testVar(console, "place", table.pack(mapName, players, gamemode))
        if not varSuccess then return end
        
        local player = console.player

		if not players or players == "false" or players == "nil" then
			players = {player}
		elseif players == "all" then
			players = Players:GetPlayers()
		else
			warn("Invalid players " .. tostring(players))
			players = {player}
		end

		if not gamemode then
			gamemode = "Range"
		end

		local success, err = game:GetService("ReplicatedStorage").Modules.EvoConsole.Objects.Bridge:InvokeServer("MapCommand", mapName, gamemode, players)
		if not success then
            console:Error(err)
            return
        end

        console:Print("Teleporting!")
		return true
    end
}

Commands.addsc = {
	name = "addsc",
    vars = {
        player = {vartype = "string", required = true, index = 1},
        amount = {vartype = "string", required = true, index = 2},
    },

	callback = function(console: Types.CConsole, player: string, amount: string)
        local varSuccess = console.testVar(console, "place", table.pack(player, amount))
        if not varSuccess then return end

		player = player == "self" and game.Players.LocalPlayer or Players:FindFirstChild(player)
		local success, err = game.ReplicatedStorage.Modules.ShopInterface.Events.c_AddStrafeCoins:InvokeServer(player, amount)
		if not success then
			console:Error("Cannot add funds to player. " .. tostring(err))
			return
		end
		console:Print("Added " .. tostring(amount) .. " to " .. player.Name .. "'s economy.")
	end
}

return Commands