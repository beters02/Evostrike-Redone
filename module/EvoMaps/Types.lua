export type map = {
    Name: string,
    Folder: Folder,
    Properties: map_properties
}

export type map_properties = {
    Enabled: boolean,
    IgnoreGamemodes: table
}

export type maps = {
    warehouse: map,
    apartments: map,
    facility: map
}

export type MapsModule = {
    Types: any,
    Maps: maps,
    
    SetMap: (self: MapsModule, map: string) -> (),
    GetMap: (self: MapsModule, map: string) -> (map?),
    GetCurrentMap: (self: MapsModule) -> (string?),
    GetRandomMapInGamemode: (self: MapsModule, gamemode: string, ignoreMaps: table?) -> (map?)
}

local types = {}
types.Map = {
    new = function(mapName: string, properties)
        properties = properties or {}
        return {
            Name = mapName,
            Folder = game.ServerStorage.Maps:FindFirstChild(mapName) or false,
            Properties = {Enabled = properties.Enabled or false, IgnoreGamemodes = properties.IgnoreGamemodes or {"Deathmatch", "1v1", "Range"}}
        } :: map
    end
}
return types