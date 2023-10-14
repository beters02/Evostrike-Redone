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
        if type(v) == "table" then
            n[i] = Tables.clone(v)
        else
            n[i] = v
        end
    end
    return n
end

-- Save copied tables in `copies`, indexed by original table.
function Tables.deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[Tables.deepcopy(orig_key, copies)] = Tables.deepcopy(orig_value, copies)
            end
            setmetatable(copy, Tables.deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Gets length of a dictionary
function Tables.getDictionaryLength(dictionary: table)
    local index = 0
    for i, v in pairs(dictionary) do
        index+=1
    end
    return index
end

--@summary Do a function to all values in a table.
function Tables.doIn(tab, callback)
    if not tab or type(tab) ~= "table" then return end
    for i, v in pairs(tab) do
        callback(v, i)
    end
end

function Tables.random(tab)
    return tab[math.random(1,#tab)]
end

return Tables