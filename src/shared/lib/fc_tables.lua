local Tables = {}
Tables.__index = Tables

-- Combines the elements of two tables
function Tables.combine(tab: table, value: table)
    for i, v in pairs(value) do
        if tonumber(i) then table.insert(tab, v) else tab[i] = v end
    end
    return tab
end

-- Clones the table
function Tables.clone(tab: table)
    local n = {}
    for i, v in pairs(tab) do
        n[i] = v
    end
    return n
end

-- Gets length of a dictionary
function Tables.getDictionaryLength(dictionary: table)
    local index = 0
    for i, v in pairs(dictionary) do
        index+=1
    end
    return index
end

return Tables