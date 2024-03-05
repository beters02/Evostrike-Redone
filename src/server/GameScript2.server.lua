--@summary Central Game Script which handles Gamemodes and Maps.

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [[ FRAMEWORK ]]
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GamemodeService2 = require(Framework.Service.GamemodeService2)
local Gamemode = require(Framework.Service.GamemodeService2.Gamemode)

-- [[ MODULES ]]

-- [[ EVENTS ]]

-- [[ VARIABLES ]]
local Connections = {}

-- [[ GAMEMODE MANAGEMENT ]]

-- [[ MAP MANAGEMENT ]]

-- [[ SCRIPT ]]

Connections.PlayerAddedGetGamemode = Players.PlayerAdded:Connect(function(player)
    
end)