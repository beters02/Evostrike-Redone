--@summary Central Game Script which handles Gamemodes and Maps.

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [[ FRAMEWORK ]]
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GameService = require(Framework.Service.GameService)
--local GamemodeService2 = require(Framework.Service.GamemodeService2)

-- [[ MODULES ]]

-- [[ EVENTS ]]

-- [[ VARIABLES ]]

-- [[ GAMEMODE MANAGEMENT ]]

-- [[ MAP MANAGEMENT ]]

-- [[ SCRIPT ]]
Players.CharacterAutoLoads = false
GameService.Initialize()