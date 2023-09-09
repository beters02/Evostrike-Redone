local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local DataStore2 = require(Framework.sm_datastore2.Location)

local module = {}
module.defaultData = require(game:GetService("ServerScriptService"):WaitForChild("playerdata"):WaitForChild("defaultPlayerData"))

function module.GetPlayerData(player)
    local store = DataStore2("PlayerData", player)

    local profile

    local success, response = pcall(function()
        profile = store:GetTable(module.defaultData)
        --print(profile)

        -- update defaults
        -- todo: change to data change function i made awhile ago
        
        -- this will update to the third table index.
        -- ex: playerdata.options.keybinds.exampleTable
        
        local _updated = false
        for mi, main in pairs(module.defaultData) do
            if not profile[mi] then _updated = true profile[mi] = main end
            if type(main) == "table" then
                for ti, tab in pairs(main) do
                    if not profile[mi][ti] then _updated = true profile[mi][ti] = tab end
                    if type(tab) == "table" then
                        for ti1, tab1 in pairs(tab) do
                            if not profile[mi][ti][ti1] then _updated = true profile[mi][ti][ti1] = tab1 end
                        end
                    end
                end
            end
        end

        if _updated then
            module.SetPlayerData(player, profile, true)
        end
    end)

    if not success then
        --print("Could not retrieve PlayerData, returning default")
        return module.defaultData
    end

    return profile
end

function module.SetPlayerData(player, newData, save)
    local store = DataStore2("PlayerData", player)

    local success, result = pcall(function()
        store:Set(newData)
    end)

    if not success then
        --print("Could not set PlayerData")
        return false
    end

    if save then
        module.SavePlayerData(player)
    end

    return result
end

function module.SavePlayerData(player)
    if RunService:IsStudio() then return true end
    local store = DataStore2("PlayerData", player)
    local success, result = pcall(function()
        store:Save()
    end)
    return success
end

return module