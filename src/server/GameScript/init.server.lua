local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GamemodeService2 = require(Framework.Service.GamemodeService2)
local ConnectionsLib = require(Framework.Module.lib.fc_rbxsignals)

local Connections = {Ended = false}
local CurrentGamemodeBaseScript = false

--@summary Ran when the first player joins
function Init(player)
    local gmScript = GamemodeService2:GetGamemodeScript(GamemodeService2.DefaultGamemode)
    local teleportData = player:GetJoinData().teleportData
    if teleportData and teleportData.RequestedGamemode then
        gmScript = GamemodeService2:GetGamemodeScript(teleportData.RequestedGamemode) or gmScript
        print("Player joined with requested gamemode.")
    end
    Start(gmScript)
end

--@summary Ran at the end of Init
function Start(gmScript)
    CurrentGamemodeBaseScript = gmScript
    gmScript = gmScript:Clone()
    gmScript.Name = "CurrentGamemode"
    gmScript.Parent = script
    Connections.Ended = gmScript:WaitForChild("Events"):WaitForChild("Ended").Event:Once(function()
        Stop()
    end)
end

function Stop(restart: boolean?)
    ConnectionsLib.SmartDisconnect(Connections.Ended)
    if restart then
        Start(CurrentGamemodeBaseScript)
    end
end

--@run
Players.CharacterAutoLoads = false
Players.PlayerAdded:Once(function(player: Player)
    Init(player)
end)