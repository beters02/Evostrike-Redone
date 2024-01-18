export type Array = {[number]: any}

local Random = {}

function Random.shuffle(tbl: Array)
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

return Random