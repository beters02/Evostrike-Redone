--@summary Inventory Mods
--         When a playerdata key needs to be changed or another function needs to be ran in the playerdata, this is where its done

local mods = {}

local priv = {
    hasBeenGivenInventoryUUIDFix = function(player, serverPlayerDataModule)
        local data = serverPlayerDataModule.GetPlayerData(player)
        if not data.hasBeenGivenInventoryUUIDFix then
            for wep, v in pairs(data.inventory.equipped) do
                local uuid = v:split("_")
                uuid = uuid[4] and uuid[4] or uuid[3]
                if not uuid or not tonumber(uuid) then
                    local def = wep == "knife" and "default_default" or "default"
                    data.inventory.equipped[wep] = def .. "_0"
                end
            end
            serverPlayerDataModule.SetPlayerData(player, data)
        end
    end
}

function mods.ApplyMods(player, serverPlayerDataModule)
    for _, v in pairs(priv) do
        v(player, serverPlayerDataModule)
    end
end

return mods