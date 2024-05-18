-- Requires GamemodeService2

-- CONFIG
local _logpref = "[EVOSTRIKE Maps] "

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
--local GamemodeService = require(Framework.Service.GamemodeService2)
local GameService = require(Framework.Service.GameService)

local remoteFunction = script:WaitForChild("RemoteFunction")

local aidstr = "rbxassetid://"
local Maps = { Stored = {
    apartments = {id = "16022806543", GamemodeIgnore = {}, Enabled = true},
    lobby = {id = "16022896979", GamemodeIgnore = {}, Enabled = true},
    warehouse = {id = "16022896979", GamemodeIgnore = {}, Enabled = true},
    facility = {id = "16022806543", GamemodeIgnore = {}, Enabled = false}, -- get package
    house = {id = "16023070217", GamemodeIgnore = {}, Enabled = false}
}}

--@summary string.upper
function upper(s)
    return string.upper(s)
end

--@summary task.spawn
function tspawn(func, ...)
    if ... then
        local packed = table.pack(...)
        return task.spawn(function() func(table.unpack(packed)) end)
    end
    return task.spawn(func)
end

function is_child_character(child)
    return child:IsA("Model") and Players:GetPlayerFromCharacter(child)
end

local is_player_admin

-- SHARED
function Maps:GetRandomMapInGamemode(gamemode: string, ignoreMaps: table?)
    local _maps = {}
    ignoreMaps = ignoreMaps or {}
    for i, v in pairs(Maps.Stored) do
        if ignoreMaps[i] or table.find(ignoreMaps, i) or not v.Properties.Enabled then continue end
        if table.find(v.Properties.IgnoreGamemodes, gamemode) then continue end
        table.insert(_maps, v)
    end
    return #_maps > 0 and _maps[math.random(1, #_maps)]
end

function Maps:RequestClientSetMap(player, mapName)
    if RunService:IsClient() then
        return remoteFunction:InvokeServer("RequestClientSetMap", mapName)
    end
    
    if is_player_admin(player) then
        Maps.LoadMap(mapName)
        GameService:RestartGame(2)
        return true
    end
end

-- SERVER
if RunService:IsServer() then

    remoteFunction.OnServerInvoke = function(player, action, mapName)
        if action == "RequestClientSetMap" then
            return Maps:RequestClientSetMap(player, mapName)
        end
    end

    is_player_admin = function(player)
        return require(game:GetService("ServerStorage").Stored.AdminIDs):IsAdmin(player)
    end

    local function destroy_workspace_child(child)
        if child:IsA("Terrain") == false
        and child:IsA("Camera") == false
        and not is_child_character(child) then
            child:Destroy()
        end
    end

    local function destroy_current_map()
        print("DESTROYING CURRENT MAP")
        workspace.Terrain:Clear()
        for _, wchild in pairs(workspace:GetChildren()) do
            destroy_workspace_child(wchild)
        end
        Lighting:ClearAllChildren()
        game.ServerStorage.CurrentSpawns:ClearAllChildren()
    end

    function load_terrain(mobj)
        workspace.Terrain:PasteRegion(
            mobj.TerrainRegion,
            Vector3int16.new(
                -math.floor(mobj.TerrainRegion.SizeInCells.X / 2),
                -math.floor(mobj.TerrainRegion.SizeInCells.Y / 2),
                -math.floor(mobj.TerrainRegion.SizeInCells.Z / 2)
            ),
            false
        )
        for matStr, matColor3 in pairs(mobj.TerrainRegion:FindFirstChild("Folder__Material__Properties"):GetAttributes()) do
            pcall(function()
                workspace.Terrain:SetMaterialColor(Enum.Material[matStr], matColor3)
            end)
        end
        for waterStr, waterProp in pairs(mobj.TerrainRegion:FindFirstChild("Folder__Water__Properties"):GetAttributes()) do
            pcall(function()
                workspace.Terrain[waterStr]	= waterProp
            end)
        end
    end

    function load_map(mobj)
        for _, spwn in pairs(mobj.Spawns:GetChildren()) do
            spwn.Parent = game.ServerStorage.CurrentSpawns
        end
        for _, wchild in pairs(mobj.Map:GetChildren()) do
            wchild.Parent = workspace
        end
    end

    function load_lighting(mobj)
        for _, lchild in pairs(mobj.Lighting:GetChildren()) do
            lchild.Parent = game.Lighting
        end
        for lStr, lv in pairs(mobj.Lighting:GetAttributes()) do
            if lStr == "MinutesAfterMidnight" then
                game.Lighting:SetMinutesAfterMidnight(lv)
            else
                game.Lighting[lStr] = lv
            end
            task.wait()
        end
    end

    local function download_map(map: string): Model
        local success, result = pcall(function()
            local tblMap = Maps.Stored[map]
            return tblMap.Enabled and InsertService:LoadAsset(tonumber(tblMap.id))
        end)
        if not success then
            return false, result
        end

        local _model = result:GetChildren()[1]
        _model.Parent = ServerStorage
        task.wait()
        result:Destroy()
        return _model
    end

    --@summary Loads a new map, destroying the current one behind it.
    function Maps.LoadMap(map: string)
        local mobj, err = download_map(map)
        if err then
            error(err)
        end
        print(_logpref .. upper"loading map")
        
        destroy_current_map()
        task.wait()
        
        tspawn(load_lighting, mobj)
        load_terrain(mobj)
        load_map(mobj)

        print(_logpref .. upper"finished loading map")
        GameService.CurrentMap = map
        --GamemodeService.CurrentMap = map
    end

end

return Maps