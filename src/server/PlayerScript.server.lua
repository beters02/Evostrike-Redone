local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerLoadedEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("playerLoadedEvent")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

PlayerLoadedEvent.OnServerEvent:Connect(function(player)
    player:SetAttribute("Loaded", true)
end)

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("Loaded", false)
    
    -- gamemode container
    local guiContainer = Instance.new("ScreenGui")
    guiContainer.Name = "Container"
    guiContainer.ResetOnSpawn = false
    guiContainer.Parent = player:WaitForChild("PlayerGui")

    -- player data
    local pde = Instance.new("RemoteEvent")
    pde.Name = "PlayerDataChanged"
    pde.Parent = player

    player.CharacterAdded:Connect(function(char)
        local hum: Humanoid = char:WaitForChild("Humanoid")
        hum.BreakJointsOnDeath = false
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    PlayerData:Save(player)
end)