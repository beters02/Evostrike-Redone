local id = {
    mapIds = {
        warehouse = {id = 14504041658, gamemodeIgnore = {"1v1"}},
        stable = {id = 14504041658, gamemodeIgnore = {"1v1"}},
        unstable = {id = 14689169953, gamemodeIgnore = {"Deathmatch", "Range"}},
        lobby = {id = 11287185880, gamemodeIgnore = {"Deathmatch", "Range", "1v1"}},
        facility = {id = 14632973077, gamemodeIgnore = {"Deathmatch", "Range", "1v1"}}
    }
}

-- Count IDs
do
    id.count = 0
    for i, v in pairs(id.mapIds) do
        id.count += 1
    end
end

id.GetTotal = function() return id.count end

id.GetRandom = function()
    local count = 0
    local index = math.random(1, id.count)
    for i, v in pairs(id.mapIds) do
        count += 1
        if count == index then
            return v
        end
    end
end

id.GetMapsInGamemode = function(gamemode: string)
    local maps = {}
    for i, v in pairs(id.mapIds) do
        if table.find(v.gamemodeIgnore, gamemode) then
            continue
        end
        table.insert(maps, v.id)
    end
    return maps
end

id.GetMaps = function(returnType: "name" | "id")
    local maps = {}
    for i, v in pairs(id.mapIds) do
        table.insert(maps, returnType == "name" and i or v)
    end
    return maps
end

id.GetMapInfoInGamemode = function(gamemode:string)
    local maps = {}
    for i, v in pairs(id.mapIds) do
        if table.find(v.gamemodeIgnore, gamemode) then
            continue
        end
        maps[i] = v.id
    end
    return maps
end

id.GetMapId = function(map: string)
    return id.mapIds[map].id or false
end

id.GetMapFromId = function(idn)
    for i, v in pairs(id.mapIds) do
        if v == idn then return i end
    end
    return false
end

id.GetCurrentMap = function()
    return id.GetMapFromId(game.PlaceId)
end

return id