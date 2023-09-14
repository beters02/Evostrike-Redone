-- [[ PlayerStats is seperate from PlayerData because the keys require different functionality ]]

local RunService = game:GetService("RunService")
local SharedRF = game:GetService("ReplicatedStorage"):WaitForChild("playerdata"):WaitForChild("remote"):WaitForChild("sharedPlayerStatsRF")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local DataStore2 = require(Framework.sm_datastore2.Location)
local Maps = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))
local Tables = require(Framework.Module.lib.fc_tables)

local playerstats = {}

--[[
    This table will be replicated for each map for the Default PlayerStats table.
]]
playerstats._defaultStats = {
    kills = 0,
    deaths = 0,
    wins = 0,
    losses = 0,
    damage = 0
}

function playerstats.GetDefaultPlayerStats()
    local def = {}
    for i, v in pairs(Maps.GetMaps("name")) do
        def[v] = Tables.clone(playerstats._defaultStats)
    end
    return
end

function playerstats.Get(player)
    if RunService:IsClient() then
        return SharedRF:InvokeServer("Get")
    end

    local default = playerstats.GetDefaultPlayerStats()

    local result
    local succ, err = pcall(function()
        result = DataStore2("PlayerStats", player):GetTable(default)
    end)

    if not result then
        return false
    end

    -- check for new maps
    local change = false
    for mapName, mapStats in pairs(default) do
        if not result[mapName] then
            change = true
            result[mapName] = Tables.clone(playerstats._defaultStats)
        end
    end
    
    if change then
        playerstats.Set(player, result)
        playerstats:Save()
        print("Player stats updated maps!")
    end

    return result
end

function playerstats.Set(player, new, save)
    if RunService:IsClient() then
        return SharedRF:InvokeServer("Set", new)
    end

    local success, err = pcall(function()
        DataStore2("PlayerStats", player):Set(new)
    end)

    if not success then
        return false
    end

    if save then
        return true, playerstats.Save(player)
    end

    return true
end

function playerstats.Save(player)
    return pcall(function()
        DataStore2("PlayerStats", player):Save()
    end)
end

--


return playerstats