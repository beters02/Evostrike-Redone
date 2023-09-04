-- Every Command will be sent with the string split table.
local Players = game:GetService("Players")

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

return Commands