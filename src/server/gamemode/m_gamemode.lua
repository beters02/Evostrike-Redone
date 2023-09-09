local Gamemode = {}
Gamemode.__index = Gamemode

-- [[ CONFIGURATION ]]
local DefaultGamemode = "Lobby"

-- [[ VARIABLES ]]
local Players = game:GetService("Players")
local GamemodeLoc = game:GetService("ServerScriptService"):WaitForChild("gamemode")
local GamemodeBase = require(GamemodeLoc:WaitForChild("class"):WaitForChild("Base"))

-- disable characterautoloads on default
Players.CharacterAutoLoads = false

-- create mutable script var
playerAddedConnection = nil
Gamemode.currentGamemode = ""
Gamemode.currentClass = nil

--[[ Init ]]
function Gamemode.Init()
    Gamemode.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
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
    end)
end

--[[
    @title Gamemode.SetGamemode

    @summary Creates a new GamemodeClass, Starts gamemode
]]
function Gamemode.SetGamemode(gamemode: string)
    local class = GamemodeLoc.class:FindFirstChild(gamemode)
    if not class then warn("Could not find gamemode module " .. gamemode) return end

    if Gamemode.currentClass then
        local c = Gamemode.currentClass
        c:Stop()
        task.wait()
    end

    -- create gamemode class
    local _c = require(class)
    class = setmetatable(_c, GamemodeBase)

    if class._init then class = class:_init() end

    class.Name = gamemode

    -- set script var
    Gamemode.currentClass = class
    Gamemode.currentGamemode = gamemode

    class:Start()
end

--[[
    @title Gamemode.GetTotalPlayerCount
    @return: table<Player>
]]
function Gamemode.GetTotalPlayerCount()
    return pcall(function()
        return Gamemode.currentClass:GetTotalPlayerCount()
    end)
end

return Gamemode