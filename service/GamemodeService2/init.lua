local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
--[[
    This Service acts less like a Service and more like an Interface,
    as it directly links to GameScript and relies on that script to process any functionality outside of the Gamemode Script.
]]

type GamemodeObject = {Name: string, Script: Script, Interface: any}

local GamemodeService = {}
GamemodeService.Location = script
GamemodeService.DefaultGamemode = "Deathmatch"
GamemodeService.MenuType = "Lobby"

local Bridge = script:WaitForChild("Bridge")
local Bindable = script:WaitForChild("Bindable")

function GamemodeService:GetGamemodeScript(gamemode: string)
    return GamemodeService.Location.GamemodeScripts:FindFirstChild(gamemode)
end

function GamemodeService:RestartGamemode(map)
    if RunService:IsClient() then
        Bridge:FireServer("RestartGamemode", map)
    else
        Bindable:Fire("Restart", map)
    end
end

function GamemodeService:SetGamemode(gamemode)
    if RunService:IsClient() then
        Bridge:FireServer("SetGamemode", gamemode)
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
        Bridge:FireClient(v, "ChangeMenuType", menuType)
    end
end

if RunService:IsServer() then
    Bridge.OnServerEvent:Connect(function(player, action, ...)
        if action == "RestartGamemode" then
            if not require(game:GetService("ServerStorage").Stored.AdminIDs):IsAdmin(player) then return end
            GamemodeService:RestartGamemode(...)
        else
            if not require(game:GetService("ServerStorage").Stored.AdminIDs):IsAdmin(player) then return end
            GamemodeService:SetGamemode(...)
        end
    end)
end

return GamemodeService