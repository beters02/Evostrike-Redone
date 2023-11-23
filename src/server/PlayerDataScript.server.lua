local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

Players.PlayerAdded:Connect(function(player)
    local pde = Instance.new("RemoteEvent")
    pde.Name = "PlayerDataChanged"
    pde.Parent = player
end)

Players.PlayerRemoving:Connect(function(player)
    PlayerData:Save(player)
end)