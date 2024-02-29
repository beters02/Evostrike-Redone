--[[
    This Service acts less like a Service and more like an Interface,
    as it directly links to GameScript and relies on that script to process any functionality outside of the Gamemode Script.
]]

type GamemodeObject = {Name: string, Script: Script, Interface: any}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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

--@summary Get a GamemodeScript from GamemodeService
function GamemodeService:GetGamemodeScript(gamemode: string)
    return GamemodeService.Location.GamemodeScripts:FindFirstChild(gamemode)
end

--@summary Fire the RestartGamemode Events for GameScript
function GamemodeService:RestartGamemode(map)
    if RunService:IsClient() then
        RemoteEvent:FireServer("RestartGamemode", map)
    else
        Bindable:Fire("Restart", map)
    end
end

--@summary Fire the SetGamemode Events for GameScript
function GamemodeService:SetGamemode(gamemode)
    if RunService:IsClient() then
        RemoteEvent:FireServer("SetGamemode", gamemode)
    else
        Bindable:Fire("Set", gamemode)
    end
end

--@summary Set MenuType for the MainMenu
function GamemodeService:SetMenuType(menuType: "Lobby" | "Game")
    if RunService:IsClient() then return end
    GamemodeService.MenuType = menuType

    for _, v in pairs(Players:GetPlayers()) do
        local mm = v.PlayerGui and v.PlayerGui:FindFirstChild("MainMenu")
        if mm then
            mm:SetAttribute("MenuType", menuType)
        end
        RemoteEvent:FireClient(v, "ChangeMenuType", menuType)
    end
end

--@summary Get the Current MenuType
function GamemodeService:GetMenuType()
    if RunService:IsServer() then
        return GamemodeService.MenuType
    end
    return RemoteFunction:InvokeServer("GetMenuType")
end

--@summary Get a connection for when the MenuType is changed. Client only.
function GamemodeService:MenuTypeChanged(callback)
    if RunService:IsServer() then return end
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