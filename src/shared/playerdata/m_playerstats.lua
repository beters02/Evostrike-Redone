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
    damage = 0,
    matchesPlayed = 0
}

function playerstats.GetDefaultPlayerStats()
    local def = {}
    for i, v in pairs(Maps.GetMaps("name")) do
        def[v] = Tables.clone(playerstats._defaultStats)
    end
    def.global = Tables.clone(playerstats._defaultStats) -- global key for all maps
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

    -- check for new maps & stats
    local change = false
    for mapName, mapStats in pairs(default) do

        -- new map
        if not result[mapName] then
            change = true
            result[mapName] = Tables.clone(playerstats._defaultStats)
        end

        -- new stat
        for statKey, statValue in pairs(mapStats) do
            if not result[mapName][statKey] then
                result[mapName][statKey] = statValue
            end
        end
    end

    if change then
        playerstats.Set(player, result)
        playerstats:Save()
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
        return false, warn(err)
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

-- Increment all stat values in a specific key
-- PCall is recommended for this function
-- Use this if you want to increment stats on a map or for global. Ex: playerstats.IncrementAllValuesInKey(player, "warehouse", {kills = 1})
function playerstats.IncrementAllValuesInKey(player, key, statIncrementData, ignoreSave) -- incrementData: {key = valueToAddToCurrent}
    local data = playerstats.Get(player)
    for i, v in pairs(statIncrementData) do
        data[key][i] += v
    end
    return playerstats.Set(player, data, not ignoreSave)
end

return playerstats