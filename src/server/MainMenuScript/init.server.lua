local Players = game:GetService("Players")
local MainMenuGUI = script:WaitForChild("MainMenu")
local Framework = require(game:GetService("ReplicatedStorage").Framework)
local ServerStorage = game:GetService("ServerStorage")
local GamemodeService2 = require(Framework.Service.GamemodeService2)
local Admins = require(ServerStorage.Stored.AdminIDs)

-- Add MainMenu with set MenuType from GamemodeService2
Players.PlayerAdded:Connect(function(player)
    local clone = MainMenuGUI:Clone()
    clone:SetAttribute("IsAdmin", Admins:IsAdmin(player))
    clone:SetAttribute("MenuType", GamemodeService2.MenuType)
    clone.Parent = player.PlayerGui
    GamemodeService2:SetMenuType(GamemodeService2.MenuType)
end)