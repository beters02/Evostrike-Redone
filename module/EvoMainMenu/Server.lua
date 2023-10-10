local Players = game:GetService("Players")
local MainMenuGui = script.Parent:WaitForChild("MainMenu")

local Server = {}

function Server:AddMainMenu(player)
    MainMenuGui:Clone().Parent = player:WaitForChild("PlayerGui")
end

function Server:GetMainMenu(player)
    return player:WaitForChild("PlayerGui"):WaitForChild("MainMenu")
end

Players.PlayerAdded:Connect(function(player)
    Server:AddMainMenu(player)
end)

return Server