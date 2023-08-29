local Gamemode = {}
Gamemode.__index = Gamemode

-- [[ CONFIGURATION ]]
local DefaultGamemode = "Lobby"

-- [[ VARIABLES ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GamemodeLoc = game:GetService("ServerScriptService"):WaitForChild("gamemode")
local Tables = require(Framework.shfc_tables.Location)

local var = { -- mutable script variables
    playerAddedConnection = nil,
    currentGamemode = "",
    currentClass = nil,
}
Gamemode = Tables.combine(Gamemode, var) -- apply script variables (var)
Players.CharacterAutoLoads = false -- disable character autoloads

--[[ BaseClass Functions ]]

function Gamemode:Start()
    
end

function Gamemode:Stop()
    
end

--[[ GamemodeModule Functions ]]

--[[
    @title Gamemode.SetGamemode

    @summary Creates a new GamemodeClass, Starts gamemode
]]

function Gamemode.SetGamemode(gamemode: string)
    local class = GamemodeLoc.class:FindFirstChild(gamemode)
    if not class then warn("Could not find gamemode " .. gamemode) return end

    if Gamemode.currentClass then
        local c = Gamemode.currentClass
        c:Stop()
        task.wait()
    end

    class = setmetatable(require(class), Gamemode)
    Gamemode.currentClass = class
    Gamemode.currentGamemode = gamemode
    class.Name = gamemode

    class:Start()
end

--[[
    @title StartPlayerAdded

    @summary The default PlayerAdded function, sets gamemode if teleportData.RequestedGamemode
]]

local function StartPlayerAddedFunction(player)
    local g = DefaultGamemode
    local data = player:GetJoinData()
    data = data and data.TeleportData
    if data and data.RequestedGamemode then
        g = data.RequestedGamemode
    end

    -- disconnect player added connection instantly to avoid gamemode starting twice
    Gamemode.playerAddedConnection:Disconnect()
    Gamemode.playerAddedConnection = nil

    -- start game as default gamemode
    Gamemode.SetGamemode(g)
end

--

function Gamemode.Init()
    Gamemode.playerAddedConnection = Players.PlayerAdded:Connect(StartPlayerAddedFunction)
end

--

function Gamemode.GetTotalPlayerCount()
    return pcall(function()
        return Gamemode.currentClass:GetTotalPlayerCount()
    end)
end

return Gamemode