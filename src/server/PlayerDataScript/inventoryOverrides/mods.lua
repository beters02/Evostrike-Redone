--@summary Inventory Mods
--         When a playerdata key needs to be changed or another function needs to be ran in the playerdata, this is where its done
--         All functions return "changed" boolean

local mods = {}

local priv = {
    hasBeenGivenInventoryUUIDFix = function(data)
        if not data.hasBeenGivenInventoryUUIDFix then
            for wep, v in pairs(data.inventory.equipped) do
                local uuid = v:split("_")
                uuid = uuid[4] and uuid[4] or uuid[3]
                if not uuid or not tonumber(uuid) then
                    local def = wep == "knife" and "default_default" or "default"
                    data.inventory.equipped[wep] = def .. "_0"
                end
            end
            data.hasBeenGivenInventoryUUIDFix = true
            return true
        end
        return false
    end,
    hasBeenGivenInventoryCaseFix = function(data)
        if not data.hasBeenGivenInventoryCaseFix then
            for i, v in pairs(data.inventory.skin) do
                print(v)
                if string.match(v, "case_") then
                    print('yuh')
                    data.inventory.skin[i] = nil
                    --table.remove(data.inventory.skin, i)
                end
            end
            data.hasBeenGivenInventoryCaseFix = true
            return true
        end
        return false
    end
}

function mods.ApplyMods(data)
    local changed = false
    for _, v in pairs(priv) do
        changed = v(data) or changed
    end
    return changed
end

return mods