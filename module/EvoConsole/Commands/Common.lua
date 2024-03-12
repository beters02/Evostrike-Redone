local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(Framework.Module.lib.fc_tables)

local Commands = {}

Commands.Help = {
	Description = "Show all available commands",
	Public = true,
	
	Function = function(self)
		for i, v in pairs(self.Commands) do
			self:Print(string.lower(i) .. ": " .. (v.Description or "Command"))
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

-- [[ PARSED PREFIX COMMANDS ]]
Commands = Tables.combine(Commands, require(script.Parent:WaitForChild("Viewmodel")))
Commands = Tables.combine(Commands, require(script.Parent:WaitForChild("Crosshair")))
print(Commands)

return Commands