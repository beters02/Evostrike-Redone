local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local EmitParticles = require(Framework.shfc_emitparticle.Location)
--local GamemodeService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("GamemodeService"))
local GamemodeService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("GamemodeService2"))
local EvoMaps = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("EvoMaps"))
local Globals = require(Framework.Module.lib.fc_global)

local ParticlesTable
task.spawn(function()
	ParticlesTable = EmitParticles.GetParticles()
end)

local Commands = {}

-- _ == player

Commands.Emit = {
	Description = "Emit specified particle from the part you are looking at",
	Public = false,
	
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

Commands.SetCameraMode = {
	Description = "Set to LockFirstPerson or Classic",
	Public = false,
	
	Function = function(_, _, cameraType)
		local t = Enum.CameraMode[cameraType] or false
		if not t then return end
		
		Players.LocalPlayer.CameraMode = t
	end,
}

Commands.AddWeapon = {
	Description = "Add specified weapon to your inventory",
	Public = false,
	
	Function = function(_, player, weapon)
		require(game:GetService("ReplicatedStorage").Services.WeaponService):AddWeapon(player, weapon)
	end
}

Commands.AddAbility = {
	Description = "Add specified ability to your inventory",
	Public = false,

	Function = function(_, player, ability)
		require(game:GetService("ReplicatedStorage").Services.AbilityService):AddAbility(player, ability)
	end
}

Commands.GM = {
	Description = "Gamemode management commands.<br /> 'get', 'set', 'restart'",
	public = false,

	Function = function(_, _, action, gamemode)
		if action == "get" then
			print(GamemodeService.Gamemode and GamemodeService.Gamemode.Name or "None")
		elseif action == "set" then
			GamemodeService:ChangeGamemode(gamemode)
		elseif action == "restart" then
			GamemodeService:RestartGamemode()
		end
	end
}

Commands.Gamemode = {
	Description = "Set the gamemode",
	Public = false,
	
	Function = function(self, _, gamemodeName)
		print('Attempt change the mothjercucking j')
		GamemodeService:SetGamemode(gamemodeName)
		print("Post attempt change the motherufkcing ad")
		--game:GetService("ReplicatedStorage").gamemode.remote.Set:FireServer(gamemodeName)
	end,
}

Commands.gm_restart = {

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
	Public = false,

	Function = function(self, player, mapName)
		if not Globals.wassert(mapName, "Could not teleport, Map Name is required!") then return end
		self:Print("Setting map to " .. mapName)
		GamemodeService:RestartGamemode()
		EvoMaps:RequestClientSetMap(player, mapName)
	end
}

Commands.qs_clearqueues = {
	Description = "Clear all queue data stores {Debug}",
	Public = false,

	Function = function()
		game:GetService("ReplicatedStorage").main.sharedMainRemotes.requestQueueFunction:InvokeServer("ClearAll")
	end
}

Commands.qs_printqueues = {
	Description = "Print all players that are in queues {Debug}",
	Public = false,

	Function = function()
		game:GetService("ReplicatedStorage").main.sharedMainRemotes.requestQueueFunction:InvokeServer("PrintAll")
	end
}

--

Commands.as_add = {
	Description = "Add an ability using AbilityService (new)",
	Public = false,

	Function = function(_, player, ability)
		require(game.ReplicatedStorage.Services.AbilityService):AddAbility(player, ability)
	end
}

--

Commands.addsc = {
	Description = "Add Strafe Coins to a player",
	Public = false,

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
	Public = false,

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

Commands.gmhud_test = {
	Description = "Test a Gamemode HUD event. Will test RoundOver",
	public = false,

	Function = function(self, player, length)
		local m1 = require(player.PlayerScripts.GamemodeHUD["1v1"])
		m1.Init()
		m1.Enable(player)
		m1.RoundOver(player)
		task.wait(tonumber(length) or 3)
		m1.RoundStart()
		m1.Disable()
	end
}

return Commands