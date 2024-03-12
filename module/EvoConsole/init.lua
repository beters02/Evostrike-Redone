--[[
    EvoConsole is a Module blah blah blah
]]

local EvoConsole = {}

local Listener = require(script.Listener)
local Tables = require(script.Tables)
local Bridge = script.Objects.Bridge
local Types = require(script.Types)
local Class = require(script.Class)
local Config = require(script.Configuration)
local CommandsFolder = script.Commands
local Events = script.Events

local RunService = game:GetService("RunService")

EvoConsole.Tables = Tables
EvoConsole.Bridge = Bridge
EvoConsole.Listener = Listener
EvoConsole.Types = Types
EvoConsole.Class = Class
EvoConsole.ConsoleTemplate = script.Objects.ConsoleGui
EvoConsole.Config = Config

-- Initialize the server listener
if RunService:IsServer() then
    Listener.init(EvoConsole)
end

-- Functionality
function EvoConsole.ClientOnly() if not RunService:IsClient() then error("This can only be used from the client!") return false end return true end
function EvoConsole.ServerOnly() if not RunService:IsServer() then warn("This can only be used from the server!") return false end return true end

-- Server Console Functions

-- Create the Console GUI and create command modules dependant on player command access
function EvoConsole:_instantiateConsole(player)
    if not EvoConsole.ServerOnly() then return end
    local Permissions = require(game:GetService("ServerStorage"):WaitForChild("Stored"):WaitForChild("AdminIDs"))

    local gui = self.ConsoleTemplate:Clone()
    gui.Enabled = false
    gui.Parent = player.PlayerGui

    local commandModules = {}

    -- insert get admin permissions here
    local higherPerm, group = Permissions:IsHigherPermission(player)
    if higherPerm then
        if group == "admin" then
            table.insert(commandModules, CommandsFolder.Admin)
        end
    end

    table.insert(commandModules, CommandsFolder.Common)
    return gui, commandModules
end

-- Client Console Functions

-- Attempt to do a Server function from the Client
function EvoConsole:ClientToServer(player: Player, key: string)
    if not EvoConsole.ClientOnly() then return end
    return self.Bridge:InvokeServer(key)
end

function EvoConsole:ClientVerifyCommand(player: Player, key: string)
    if not EvoConsole.ClientOnly() then return end
    return Events.VerifyCommandEvent:InvokeServer(key)
end

-- Create a console object and assign it to a player
function EvoConsole:Create(player)
    if not EvoConsole.ClientOnly() then return end -- only used on client
    return Class.new(EvoConsole, player)
end

return setmetatable(EvoConsole, {__index = EvoConsole})