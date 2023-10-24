local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Types = require(script:WaitForChild("Types"))
local StoredMaps = {
    lobby = Types.Map.new("warehouse"),
    warehouse = Types.Map.new("warehouse", {Enabled = true, IgnoreGamemodes = {}}),
    apartments = Types.Map.new("apartments", {Enabled = false, IgnoreGamemodes = {}}),
    facility = Types.Map.new("facility", {Enabled = false}),
    house = Types.Map.new("house", {Enabled = true, IgnoreGamemodes = {}})
}

-- [[ Private Map Utility ]]
local MapUtil = {
    Destroy = function()
        print("DESTROYING CURRENT MAP")
        workspace.Terrain:Clear()

        for _, wchild in pairs(workspace:GetChildren()) do
            if wchild:IsA("Terrain") == false and wchild:IsA("Camera") == false and not (wchild:IsA("Model") and Players:GetPlayerFromCharacter(wchild)) then
                wchild:Destroy()
            end
        end
        for _, lchild in pairs(Lighting:GetChildren()) do
            lchild:Destroy()
        end
    end,

    Load = function(map)
        print("LOADING NEW MAP")
        workspace.Terrain:PasteRegion(
            map.Folder.TerrainRegion,
            Vector3int16.new(
                -math.floor(map.Folder.TerrainRegion.SizeInCells.X / 2),
                -math.floor(map.Folder.TerrainRegion.SizeInCells.Y / 2),
                -math.floor(map.Folder.TerrainRegion.SizeInCells.Z / 2)
            ),
            false
        )

        for _, wchild in pairs(map.Folder.Map:GetChildren()) do
            wchild:Clone().Parent = workspace
        end
        for _, lchild in pairs(map.Folder.Lighting:GetChildren()) do
            lchild:Clone().Parent = game.Lighting
        end
        for lStr, lv in pairs(map.Folder.Lighting:GetAttributes()) do
            if lStr == "MinutesAfterMidnight" then
                game.Lighting:SetMinutesAfterMidnight(lv)
            else
                game.Lighting[lStr] = lv
            end
            task.wait()
        end
        for matStr, matColor3 in pairs(map.Folder.TerrainRegion:FindFirstChild("Folder__Material__Properties"):GetAttributes()) do
            pcall(function()
                workspace.Terrain:SetMaterialColor(Enum.Material[matStr], matColor3)
            end)
        end
        for waterStr, waterProp in pairs(map.Folder.TerrainRegion:FindFirstChild("Folder__Water__Properties"):GetAttributes()) do
            pcall(function()
                workspace.Terrain[waterStr]	= waterProp
            end)
        end
    end
}

-- [[ Public Maps Functions ]]
Maps = {
    Types = Types,
    Maps = StoredMaps,

    GetMap = function(self, mapName) return StoredMaps[mapName] end,
    GetCurrentMap = function(self) return workspace:GetAttribute("CurrentMap") end,

    SetMap = function(self, mapName)
        local map = self:GetMap(mapName)
        assert(map, "This map does not exist! " .. tostring(mapName))
        assert(map.Folder, "This map does not have a map folder!" .. mapName)
        MapUtil.Destroy()
        MapUtil.Load(map)
        workspace:SetAttribute("CurrentMap", mapName)
        print("NEW MAP LOADED! [ " .. mapName .. " ]")
    end,

    GetRandomMapInGamemode = function(self, gamemode: string, ignoreMaps: table?)
        local _maps = {}
        ignoreMaps = ignoreMaps or {}
        for i, v in pairs(StoredMaps) do
            if ignoreMaps[i] or table.find(ignoreMaps, i) or not v.Properties.Enabled then continue end
            if table.find(v.Properties.IgnoreGamemodes, gamemode) then continue end
            table.insert(_maps, v)
        end
        return #_maps > 0 and _maps[math.random(1, #_maps)]
    end
}

return Maps :: Types.MapsModule