local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
--[[
    This Service acts less like a Service and more like an Interface,
    as it directly links to GameScript and relies on that script to process any functionality outside of the Gamemode Script.
]]

type GamemodeObject = {Name: string, Script: Script, Interface: any}

local GamemodeService = {}
GamemodeService.Location = script
GamemodeService.DefaultGamemode = "Deathmatch"
GamemodeService.MenuType = "Lobby"
GamemodeService.CurrentMap = "warehouse"
GamemodeService.CurrentGamemodeModule = false
GamemodeService.Gamemode = require(script:WaitForChild("Gamemode"))

local RemoteFunction = script:WaitForChild("RemoteFunction")
local RemoteEvent = script:WaitForChild("RemoteEvent")
local Bindable = script:WaitForChild("Bindable")

function GamemodeService:GetGamemodeScript(gamemode: string)
    if gamemode == "1v1" and RunService:IsServer() then
        return ServerStorage.GamemodeScripts["1v1"]
    end
    return GamemodeService.Location.GamemodeScripts:FindFirstChild(gamemode)
end

function GamemodeService:RestartGamemode(map)
    if RunService:IsClient() then
        RemoteEvent:FireServer("RestartGamemode", map)
    else
        Bindable:Fire("Restart", map)
    end
end

function GamemodeService:SetGamemode(gamemode)
    if RunService:IsClient() then
        RemoteEvent:FireServer("SetGamemode", gamemode)
    else
        Bindable:Fire("Set", gamemode)
    end
end

function GamemodeService:SetMenuType(menuType: "Lobby" | "Game")
    if RunService:IsClient() then
        return
    end
    GamemodeService.MenuType = menuType
    for _, v in pairs(Players:GetPlayers()) do
        local mm = v.PlayerGui and v.PlayerGui:FindFirstChild("MainMenu")
        if mm then
            mm:SetAttribute("MenuType", menuType)
        end
        RemoteEvent:FireClient(v, "ChangeMenuType", menuType)
    end
end

function GamemodeService:GetMenuType()
    if RunService:IsServer() then
        return GamemodeService.MenuType
    end
    return RemoteFunction:InvokeServer("GetMenuType")
end

function GamemodeService:MenuTypeChanged(callback)
    if RunService:IsServer() then
        return
    end
    return RemoteEvent.OnClientEvent:Connect(function(action, newMenuType)
        if action == "ChangeMenuType" then
            callback(newMenuType)
        end
    end)
end

if RunService:IsServer() then
    RemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        if action == "RestartGamemode" then
            if not require(game:GetService("ServerStorage").Stored.AdminIDs):IsAdmin(player) then return end
            GamemodeService:RestartGamemode(...)
        else
            if not require(game:GetService("ServerStorage").Stored.AdminIDs):IsAdmin(player) then return end
            GamemodeService:SetGamemode(...)
        end
    end)
    RemoteFunction.OnServerInvoke = function(_, action)
        if action == "GetMenuType" then
            return GamemodeService:GetMenuType()
        end
    end
end

return GamemodeService