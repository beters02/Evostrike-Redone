local Gamemode = {}
Gamemode.__index = Gamemode

-- [[ CONFIGURATION ]]
local DefaultGamemode = "Lobby"

-- [[ VARIABLES ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamemodeLoc = game:GetService("ServerScriptService"):WaitForChild("gamemode")
local GamemodeBase = require(GamemodeLoc:WaitForChild("class"):WaitForChild("Base"))
local StoredMapIDs = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))
local EvoMM = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("EvoMMWrapper"))

-- disable characterautoloads on default
Players.CharacterAutoLoads = false

-- create mutable script var
playerAddedConnection = nil
Gamemode.currentGamemode = ""
Gamemode.currentClass = nil

--[[ Init ]]
function Gamemode.Init()
    Gamemode.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        
        local g = nil
        local data = player:GetJoinData()

        if data then
            if data.TeleportData and data.TeleportData.RequestedGamemode then
                g = data.TeleportData.RequestedGamemode
            end
        end

        if not g then
            data = EvoMM.MatchmakingService:GetUserData(player)
            if data then
                if data.TeleportData and data.TeleportData.RequestedGamemode then
                    g = data.TeleportData.RequestedGamemode
                end
            end
        end

        if not g then g = DefaultGamemode end

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
        print('Stopping gamemode')
        task.wait(0.5)
    end

    -- init mm service
    if gamemode ~= "Lobby" then
        EvoMM.MatchmakingService:SetIsGameServer(true, false)
    else
        EvoMM.MatchmakingService:SetIsGameServer(false, false)
    end

    -- create gamemode class
    local mod = class
    class = setmetatable(require(class), GamemodeBase)

    if class._init then class = class:_init() end

    class.Name = gamemode
    class.maps = StoredMapIDs.GetMapInfoInGamemode(gamemode)

    -- set script var
    Gamemode.currentClass = class
    Gamemode.currentGamemode = gamemode

    -- add location var
    class.Location = mod

    -- fire gamemode changed event
    ReplicatedStorage.gamemode.remote.ChangedEvent:FireAllClients(gamemode)

    task.wait(0.5)

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

--[[
    Returns the default spawn of the current gamemode
]]
function Gamemode.GetSpawn()
    return Gamemode.currentClass.objects.spawns.Default
end

function Gamemode.GetQueueableGamemodes()
    local gm = {}
    for i, v in pairs(GamemodeLoc.class:GetChildren()) do
        if require(v).canQueue then
            table.insert(gm, v.Name)
        end
    end
    return gm
end

return Gamemode