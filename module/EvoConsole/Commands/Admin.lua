local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local EmitParticles = require(Framework.Module.lib.fc_emitparticle)
local GamemodeService = require(Framework.Service.GamemodeService2)
local EvoMaps = require(Framework.Module.EvoMaps)
local Globals = require(Framework.Module.lib.fc_global)
local GamemodeEvents = ReplicatedStorage.GamemodeEvents
local PlayerData = require(Framework.Module.PlayerData)
local GameService = require(Framework.Service.GameService)

local storedSvList = false

local ParticlesTable
task.spawn(function()
	ParticlesTable = EmitParticles.GetParticles()
end)

local Commands = {}

-- _ == player

Commands.emit = {
	Description = "Emit specified particle from the part you are looking at",
	Public = true,
	
	Function = function(self, _, particle, ...)
		-- raycast
		local player = Players.LocalPlayer
		local cam = workspace.CurrentCamera
		local mos = player:GetMouse()
		local unit = cam:ScreenPointToRay(mos.X, mos.Y)
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {player, cam}
		params.FilterType = Enum.RaycastFilterType.Exclude
		local result = workspace:Raycast(unit.Origin, unit.Direction * 100, params)
		if result and result.Instance then
			-- find particle
			if not ParticlesTable[particle] then return end
			-- emit function
			EmitParticles.Emit(result.Instance, ParticlesTable[particle], ...)
		end
	end,
}

Commands.setcameramode = {
	Description = "Set to LockFirstPerson or Classic",
	Public = true,
	
	Function = function(_, _, cameraType)
		local t = Enum.CameraMode[cameraType] or false
		if not t then return end
		
		Players.LocalPlayer.CameraMode = t
	end,
}

Commands.addweapon = {
	Description = "Add specified weapon to your inventory",
	Public = true,
	
	Function = function(_, player, weapon)
		require(game:GetService("ReplicatedStorage").Services.WeaponService):AddWeapon(player, weapon)
	end
}

Commands.addability = {
	Description = "Add specified ability to your inventory",
	Public = true,

	Function = function(_, player, ability)
		require(game:GetService("ReplicatedStorage").Services.AbilityService):AddAbility(player, ability)
	end
}

Commands.Gamemode = {
	Description = "Set the gamemode",
	Public = true,
	
	Function = function(self, _, gamemodeName)
		self:Print("This command is not available right now.")
		--[[print('Attempt change the mothjercucking j')
		GamemodeService:SetGamemode(gamemodeName)
		print("Post attempt change the motherufkcing ad")
		--game:GetService("ReplicatedStorage").gamemode.remote.Set:FireServer(gamemodeName)]]
	end,
}

Commands.Place = {
	Description = "Teleport player or players to a different place",
	Public = false,

	Function = function(self, player, mapName, players, gamemode)
		if not mapName then
			warn("Could not teleport, Map Name is requred!")
			return
		end

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
		if not success then warn(err) return end

		self:Print("Teleporting!")
		return true
	end
}

Commands.Map = {
	Description = "Set the game's map. Will restart the current gamemode.",
	Public = true,

	Function = function(self, player, mapName)
		if not Globals.wassert(mapName, "Could not teleport, Map Name is required!") then return end
		self:Print("Setting map to " .. mapName)
		local canSetMap = EvoMaps:RequestClientSetMap(player, mapName)
		if canSetMap then
			self:Print('Restarting in 2 sec')
		end
	end
}

--

Commands.addsc = {
	Description = "Add Strafe Coins to a player",
	Public = true,

	Function = function(self, _, player, amount)
		player = player == "self" and game.Players.LocalPlayer or Players:FindFirstChild(player)
		if not player then
			self:Error("Cannot find player " .. tostring(player) .. ". If you want to add to yourself, put 'self' for {player}")
			return
		end
		local success, err = game.ReplicatedStorage.Modules.ShopInterface.Events.c_AddStrafeCoins:InvokeServer(player, amount)
		if not success then
			self:Error("Cannot add funds to player. " .. tostring(err))
			return
		end
		self:Print("Added " .. tostring(amount) .. " to " .. player.Name .. "'s economy.")
	end
}

Commands.addinvitem = {
	Description = "Add Strafe Coins to a player",
	Public = true,

	Function = function(self, _, player, item) -- player is sent player via text
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

Commands.addbot = {
	Description = "Add a bot",
	Public = true,

	Function = function(self)
		Framework.Service.GameService.Remotes.BotSpawn:FireServer()
		return self:Print("Adding bot...")
	end
}

Commands.svlist = {
	Description = "List all of the sv commands.",
	Public = true,

	Function = function(self)
		if not storedSvList then
			storedSvList = Framework.Service.GameService.Remotes.Get:InvokeServer("ServerVars")
		end

		for _, v in pairs(storedSvList) do
			self:Print(v)
		end
	end
}

Commands.mp_restartgame = {
	Description = "Restart the game without changing the GameOptions.",
	Public = true,

	Function = function(self, _, length)
		local success, err = Framework.Service.GameService.Remotes.MultiplayerFunction:InvokeServer("RestartGame", length)
		if not success then
			err = err or "Command error, no error message provided."
			return self:Error(err)
		end
		return self:Print("Restarting game...")
	end
}

Commands.mp_resetgame = {
	Description = "Restart the game and reset GameOptions.",
	Public = true,

	Function = function(self, _, length)
		local success, err = Framework.Service.GameService.Remotes.MultiplayerFunction:InvokeServer("ResetGame", length)
		if not success then
			err = err or "Command error, no error message provided."
			return self:Error(err)
		end
		return self:Print("Restarting game...")
	end
}

return Commands