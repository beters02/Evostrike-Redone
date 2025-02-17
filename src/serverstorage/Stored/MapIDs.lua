local id = {
    mapIds = {
        stable = {id = 14504041658, gamemodeIgnore = {"Deathmatch", "1v1"}},
        unstable = {id = 14689169953, gamemodeIgnore = {"Deathmatch", "1v1"}},

        warehouse = {id = 14504041658, gamemodeIgnore = {}},
        apartments = {id = 11674745036, gamemodeIgnore = {"Deathmatch"}},
        lobby = {id = 11287185880, gamemodeIgnore = {"Deathmatch", "1v1"}},
        facility = {id = 14632973077, gamemodeIgnore = {"Deathmatch", "1v1"}},
    }
}

export type map = {ID: number, Folder: Folder}
export type mapids = {stable: map, unstable: map, warehouse: map, lobby: map, facility: map}

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