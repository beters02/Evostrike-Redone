local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

local Commands = {}

Commands.Help = {
	Description = "Show all available commands",
	Public = true,
	
	Function = function(self)
		for i, v in pairs(self.Commands) do
			self:Print(string.lower(i) .. ": " .. v.Description or "Command")
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

-- Made for Evostrike
Commands.Stats = {
	Description = "Show FPS and Velocity",
	Public = true,
	
	Function = function()
		local statsGui = Players.LocalPlayer.PlayerGui.Stats
		statsGui.Enabled = not statsGui.Enabled
	end,
}

Commands.viewmodel_fov = {
	Description = "Change the Viewmodel FOV",
	Public = true,

	Function = function(self, _, value)
		if not value then
			self:Print(PlayerData:GetPath("options.camera.FOV"))
			return
		end

		if tonumber(value) then
			PlayerData:SetPath("options.camera.FOV", tonumber(value))
			self:Print("viewmodel_fov " .. tostring(value))
		end
	end
}

Commands.viewmodel_bob = {
	Description = "Change the Viewmodel Bob Setting",
	Public = true,

	Function = function(self, _, value)
		if not value then
			self:Print("viewmodel_bob " .. PlayerData:GetPath("options.camera.vmBob"))
			return
		end

		if tonumber(value) then
			PlayerData:SetPath("options.camera.vmBob", tonumber(value))
			self:Print("viewmodel_bob " .. tostring(value))
		end
	end
}

Commands.vm_fov = Commands.viewmodel_fov
Commands.vm_bob = Commands.viewmodel_bob

return Commands