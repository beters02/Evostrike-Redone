local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Types = require(ReplicatedStorage.Framework.Types)
local WeaponService = require(ReplicatedStorage.Services.WeaponService)
local AbilityService = require(ReplicatedStorage.Services.AbilityService)

local Commands = {}
local storedSvList

-- Teleporting
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

		local success, err = ReplicatedStorage.Modules.EvoConsole.Objects.Bridge:InvokeServer("MapCommand", mapName, gamemode, players)
		if not success then
            console:Error(err)
            return
        end

        console:Print("Teleporting!")
		return true
    end
}
--

-- Economy & Inventory
Commands.addsc = {
	name = "addsc",
    vars = {
        player = {vartype = "string", required = true, index = 1},
        amount = {vartype = "number", required = true, index = 2},
    },

	callback = function(console: Types.CConsole, player: string, amount: string)
        local varSuccess = console.testVar(console, "addsc", table.pack(player, amount))
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

Commands.addinvitem = {
	name = "addinvitem",
    vars = {
        player = {vartype = "string", required = true, index = 1},
        item = {vartype = "string", required = true, index = 2},
    },

	callback = function(self, player, item) -- player is sent player via text
		local varSuccess = self.testVar(self, "addinvitem", table.pack(player, item))
        if not varSuccess then return end

		player = player == "self" and game.Players.LocalPlayer or Players:FindFirstChild(player)
		if not player then
			self:Error("Cannot find player " .. tostring(player) .. ". If you want to add to yourself, put 'self' for {player}")
			return
		end
		local success, err = game.ReplicatedStorage.Modules.ShopInterface.Events.c_AddInventoryItem:InvokeServer(player, item)
		if not success then
			self:Error("Cannot add funds to player. " .. tostring(err))
			return
		end
		self:Print("Added " .. tostring(item) .. " to " .. player.Name .. "'s inventory.")
	end
}
--

-- In Game Features
Commands.addweapon = {
	name = "addweapon",
    vars = {
        weapon = {vartype = "string", required = true, index = 1},
    },
	
	callback = function(console, weapon)
		local varSuccess = console.testVar(console, "addweapon", table.pack(weapon))
        if not varSuccess then return end
		WeaponService:AddWeapon(game.Players.LocalPlayer, weapon)
	end
}

Commands.addability = {
	name = "addability",
    vars = {
        ability = {vartype = "string", required = true, index = 1},
    },

	callback = function(console, ability)
		local varSuccess = console.testVar(console, "addability", table.pack(ability))
        if not varSuccess then return end
		AbilityService:AddAbility(game.Players.LocalPlayer, ability)
	end
}

Commands.addbot = {
	name = "addbot",
    vars = {},

	callback = function(self)
		Framework.Service.GameService.Remotes.BotSpawn:FireServer()
		return self:Print("Adding bot...")
	end
}

Commands.svlist = {
	name = "svlist",
    vars = {},

	callback = function(self)
		if not storedSvList then
			storedSvList = Framework.Service.GameService.Remotes.Get:InvokeServer("ServerVars")
		end

		for _, v in pairs(storedSvList) do
			self:Print(v)
		end
	end
}

Commands.mp_restartgame = {
	name = "mp_restartgame",
    vars = {
        length = {vartype = "number", required = true, index = 1},
    },

	callback = function(self, length)
		length = length and tonumber(length) or 1

		local success, err = Framework.Service.GameService.Remotes.MultiplayerFunction:InvokeServer("RestartGame", length)
		if not success then
			err = err or "Command error, no error message provided."
			return self:Error(err)
		end
		return self:Print("Restarting game...")
	end
}

Commands.setcameramode = {
	name = "setcameramode",
    vars = {
        cameraType = {vartype = "string", required = true, index = 1},
    },

	
	callback = function(self, cameraType)
		local varSuccess = self.testVar(self, "setcameramode", table.pack(cameraType))
        if not varSuccess then return end

		local t = Enum.CameraMode[cameraType] or false
		if not t then
			self:Error("CameraType invalid: " .. cameraType)
			return
		end
		
		Players.LocalPlayer.CameraMode = t
		self:Print("Set camera mode to: " .. cameraType)
	end
}
--

return Commands