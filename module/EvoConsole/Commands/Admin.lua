local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local EmitParticles = require(Framework.shfc_emitparticle.Location)

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
	
	Function = function(self, _, cameraType)
		local t = Enum.CameraMode[cameraType] or false
		if not t then return end
		
		Players.LocalPlayer.CameraMode = t
	end,
}

Commands.AddWeapon = {
	Description = "Add specified weapon to your inventory",
	Public = false,
	
	Function = function(self, _, weaponName)
		game:GetService("ReplicatedStorage").weapon.remote.addremove:FireServer("Add", weaponName)
	end
}

Commands.Gamemode = {
	Description = "Set the gamemode",
	Public = false,
	
	Function = function(self, _, gamemodeName)
		game:GetService("ReplicatedStorage").gamemode.remote.Set:FireServer(gamemodeName)
	end,
}

Commands.gm_forcestart = {
	Description = "Force Start a gamemode with Bots filling in for missing players.",

	Function = function()
		game:GetService("ReplicatedStorage").gamemode.remote.ForceStart:FireServer()
	end
}

Commands.Map = {
	Description = "Teleport player or players to map",
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

return Commands