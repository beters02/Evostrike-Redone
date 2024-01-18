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
    clone.Name = "MainMenuGui"
    clone.Parent = player.PlayerGui

    --DELETE THIS AFTER MAINMENU2
    GamemodeService2:SetMenuType(GamemodeService2.MenuType)

    --[[ test clone for MainMenu2
    local clone2 = MainMenuGUI:Clone()
    clone2.Name = "MainMenu2"
    clone2.Enabled = false
    clone2.Parent = player.PlayerGui]]
end)