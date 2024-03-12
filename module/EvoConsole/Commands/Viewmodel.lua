-- [[ VIEWMODEL COMMON COMMANDS ]]

-- [[ CONFIGURATION ]]
local PREFIX = "viewmodel_"
local ALIAS = "vm_"
local DEFAULT_COMMANDS_TO_PARSE = {"X", "Y", "Z", "Bob"} -- Commands with Default PlayerData Key (options.camera.vm ...)
local CUSTOM_COMMANDS_TO_PARSE = {"FOV"} -- Commands without vm prefix PlayerData Key (options.camera. ..)

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

local Viewmodel = {}

local function initDefaultKeyCommand(command)
    local low = string.lower(command)
    Viewmodel[PREFIX .. string.lower(low)] = {
        Description = "Change the Viewmodel " .. tostring(command) .. " Setting",
		Public = true,

		Function = function(self, _, value)
			setIntOption(self, "camera", "vm" .. low, value)
		end
    }
    Viewmodel[ALIAS .. command] = Viewmodel[PREFIX .. command]
end

local function initCustomKeyCommand(command)
    local low = string.lower(command)
    Viewmodel[PREFIX .. low] = {
        Description = "Change the Viewmodel " .. tostring(command) .. " Setting",
		Public = true,

		Function = function(self, _, value)
			setIntOption(self, "camera", command, value)
		end
    }
    Viewmodel[ALIAS .. low] = Viewmodel[PREFIX .. low]
end

local function compileCommands()
    doAllInTable(DEFAULT_COMMANDS_TO_PARSE, initDefaultKeyCommand)
    doAllInTable(CUSTOM_COMMANDS_TO_PARSE, initCustomKeyCommand)
end

compileCommands()

return Viewmodel