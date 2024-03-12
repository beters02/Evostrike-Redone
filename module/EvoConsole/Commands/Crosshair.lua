-- [[ CROSSHAIR COMMON COMMANDS ]]

-- [[ CONFIGURATION ]]
local PREFIX = "crosshair_"
local ALIAS = "cr_"
local DEFAULT_COMMANDS_TO_PARSE = {"red", "blue", "green", "gap", "size", "thickness"}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

local function doAllInTable(tbl, callback)
    for i, v in pairs(tbl) do
        callback(v, i)
    end
end

local function setIntOption(self, optionKey, valueKey, value)
	local path = "options." .. optionKey .. "." .. valueKey
	if not value then
		return self:Print(path .. " " .. PlayerData:GetPath(path))
	end
    if not tonumber(value) then
	    return self:Error("Cannot set int value to string.")
    end
	local success = PlayerData:SetOptionValue(optionKey, valueKey, tonumber(value))
    if not success then
        return self:Error("Cannot set option to this value.")
    end
    return self:Print(path .. " " .. value)
end

local Crosshair = {}

local function initDefaultKeyCommand(command)
    local low = string.lower(command)
    Crosshair[PREFIX .. string.lower(low)] = {
        Description = "Change the Crosshair " .. tostring(command) .. " Setting",
		Public = true,

		Function = function(self, _, value)
			setIntOption(self, "crosshair", low, value)
		end
    }
    Crosshair[ALIAS .. command] = Crosshair[PREFIX .. command]
end

local function compileCommands()
    doAllInTable(DEFAULT_COMMANDS_TO_PARSE, initDefaultKeyCommand)
end

compileCommands()

return Crosshair