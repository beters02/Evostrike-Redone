-- Every Command will be sent with the string split table.
local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local EmitParticles = require(Framework.shfc_emitparticle.Location)
local ParticlesTable
task.spawn(function()
	ParticlesTable = EmitParticles.GetParticles()
end)

local Commands = {}

Commands.Help = {
	Description = "Show all available commands",
	Public = true,
	
	Function = function()
		for i, v in pairs(Commands) do
			if v.Public then
				print(string.lower(i) .. ": " .. v.Description or "Command")
			end
		end
	end,
}

Commands.Clear = { 
	Description = "Clear the current console log",
	Public = true,
	
	Function = function()
		script.events.Clear:Fire() -- Event Function in ConsoleModule, Event Connection in Main
	end,
}

Commands.Close = {
	Description = "Close the console",
	Public = true,
	
	Function = function()
		script.events.Close:Fire() -- Event Function and Connection in Main
	end,
}

Commands.Stats = {
	Description = "Show FPS and Velocity",
	Public = true,
	
	Function = function()
		local statsGui = Players.LocalPlayer.PlayerGui.Stats
		statsGui.Enabled = not statsGui.Enabled
	end,
}

Commands.Emit = {
	Description = "Emit specified particle from the part you are looking at",
	Public = true,
	
	Function = function(_, particle, ...)
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
	Public = true,
	
	Function = function(_, cameraType)
		local t = Enum.CameraMode[cameraType] or false
		if not t then return end
		
		Players.LocalPlayer.CameraMode = t
	end,
}

Commands.AddWeapon = {
	Description = "Add specified weapon to your inventory",
	Public = true,
	
	Function = function(_, weaponName)
		game:GetService("ReplicatedStorage").weapon.remote.addremove:FireServer("Add", weaponName)
	end,	
}

Commands.Gamemode = {
	Description = "Set the gamemode",
	Public = true,
	
	Function = function(_, gamemodeName)
		game:GetService("ReplicatedStorage").gamemode.remote.Set:FireServer(gamemodeName)
	end,
}

Commands.Map = {
	Description = "Teleport player or players to map",
	Public = true,

	Function = function(_, mapName, players)
		if not mapName then
			warn("Could not teleport, Map Name is requred!")
			return
		end

		if players then
			if players == "all" then
				players = Players:GetPlayers()
			end
		end

		local success, err = game:GetService("ReplicatedStorage").main.sharedMainRemotes.requestQueueFunction:InvokeServer("MapCommand", mapName, players)
		if not success then warn(err) return end
		print("Teleporting!")
		return
	end
}

Commands.qs_clearqueues = {
	Description = "Clear all queue data stores {Debug}",
	Public = true,

	Function = function()
		game:GetService("ReplicatedStorage").main.sharedMainRemotes.requestQueueFunction:InvokeServer("ClearAll")
	end
}

Commands.qs_printqueues = {
	Description = "Print all players that are in queues {Debug}",
	Public = true,

	Function = function()
		game:GetService("ReplicatedStorage").main.sharedMainRemotes.requestQueueFunction:InvokeServer("PrintAll")
	end
}

return Commands