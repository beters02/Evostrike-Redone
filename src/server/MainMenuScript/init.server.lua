local Players = game:GetService("Players")
local MainMenu2GUI = script:WaitForChild("MainMenu2")

-- Add MainMenu with set MenuType from GamemodeService2
Players.PlayerAdded:Connect(function(player)
    local clone2 = MainMenu2GUI:Clone()
    clone2.Name = "MainMenuGui"
    clone2.Enabled = true
    clone2.Parent = player.PlayerGui
end)