local tables = {}

-- merge two tables where a0 overwrites a1
function tables.merge(a0, a1)
    for i, v in pairs(a0) do
        a1[i] = v
    end
    return a1
end

return tables