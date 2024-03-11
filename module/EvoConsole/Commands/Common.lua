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

-- Made for Evostrike
Commands.Stats = {
	Description = "Show FPS and Velocity",
	Public = true,
	
	Function = function()
		local statsGui = Players.LocalPlayer.PlayerGui.Stats
		statsGui.Enabled = not statsGui.Enabled
	end,
}

local function setIntOption(self, optionKey, valueKey, value)
	local path = "options." .. optionKey .. "." .. valueKey
	print(path)

	if not value then
		self:Print(path .. " " .. PlayerData:GetPath(path))
		return
	end

	if tonumber(value) then
		local didSet = PlayerData:SetOptionValue(optionKey, valueKey, tonumber(value))
		if didSet then
			self:Print(path .. " " .. value)
			return
		end

		self:Error("Cannot set option to this value.")
		return
	end

	self:Error("Cannot set int value to string.")
	return
end

-- Initialize Viewmodel Commands
for _, v in pairs({"X", "Y", "Z", "Bob"}) do

	-- init viewmodel_ ..
	Commands["viewmodel_" .. v] = {
		Description = "Change the Viewmodel " .. tostring(v) .. " Setting",
		Public = true,

		Function = function(self, _, value)
			setIntOption(self, "camera", "vm" .. v, value)
		end
	}

	-- init alias vm_ ..
	Commands["vm_" .. v] = Commands["viewmodel_" .. v]
end

-- FOV command has to be seperate because of Data Key difference.
Commands.viewmodel_fov = {
	Description = "Change the Viewmodel FOV",
	Public = true,

	Function = function(self, _, value)
		setIntOption(self, "camera", "FOV", value)
	end
}
Commands.vm_fov = Commands.viewmodel_fov

-- Init Crosshair Commands
-- crosshair_red ...

-- Int Values
for _, v in pairs({"red", "blue", "green", "gap", "size", "thickness"}) do
	Commands["crosshair_" .. v] = {
		Description = "Change the Crosshair " .. v,
		Public = true,

		Function = function(self, _, value)
			setIntOption(self, "crosshair", v, value)
		end
	}
end

-- True/False Values

return Commands