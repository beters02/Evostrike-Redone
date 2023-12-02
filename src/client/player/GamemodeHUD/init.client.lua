local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamemodeHUDEvents = ReplicatedStorage.GamemodeEvents.HUD

-- Current Gamemode HUD Module
local gamemodeModule = false

GamemodeHUDEvents:WaitForChild("INIT").OnClientEvent:Connect(function(gamemode)
    print('INit received')
    if gamemodeModule then
        gamemodeModule.Disable()
    end

    gamemodeModule = require(script[gamemode])
    gamemodeModule.Init()
end)


GamemodeHUDEvents:WaitForChild("START").OnClientEvent:Connect(function(enemy)
    gamemodeModule.Enable(enemy)
end)


GamemodeHUDEvents:WaitForChild("StartTimer").OnClientEvent:Connect(function(length)
    gamemodeModule.StartTimer(length)
end)


GamemodeHUDEvents:WaitForChild("ChangeScore").OnClientEvent:Connect(function(data)
    gamemodeModule.ChangeScore(data)
end)


GamemodeHUDEvents:WaitForChild("ChangeRound").OnClientEvent:Connect(function(round)
    gamemodeModule.ChangeRound(round)
end)