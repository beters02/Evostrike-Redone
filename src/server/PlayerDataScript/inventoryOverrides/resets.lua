--@summary Inventory Resets
--         When a playerdata key needs to be reset, this is where you would do it.

local resets = {}

--@summary Loop through new reset states, reset through invs if necessary
function resets.main(invs, data, group)
    local changed, reset = false, false
    for i, func in pairs(resets) do
        if i == "main" then continue end
        reset = func(data)
        if reset then
            data[i] = true
            invs.Give[i](data, group)
            changed = true
        end
        reset = false
    end
    return changed
end

--@summary new inventory reset state data, sets all resets to true
function resets.new(data)
    for i, v in pairs(resets.get()) do
        data[i] = true
    end
end

--@summary get all reset keys
function resets.get()
    local strs = {}
    for i, _ in pairs(resets) do
        if i == "main" or i == "get" then continue end
        table.insert(strs, i)
    end
    return strs
end

--[[ inventory reset functions ]]

--@return to reset - bool
function resets.hasBeenGivenInventoryReset2(data)
    if not data.hasBeenGivenInventoryReset2 then
        return true
    end
end

return resets