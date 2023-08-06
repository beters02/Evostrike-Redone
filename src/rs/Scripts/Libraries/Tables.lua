local Tables = {}
Tables.__index = Tables

-- Combines the elements of two tables
function Tables.combine(table: table, value: table)
    for i, v in ipairs(value) do
        table[i] = v
    end
    return table
end

-- Clones the table
function Tables.clone(table: table)
    local n = {}
    for i, v in ipairs(table) do
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