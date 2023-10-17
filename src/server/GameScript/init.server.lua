local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GamemodeService2 = require(Framework.Service.GamemodeService2)
local ConnectionsLib = require(Framework.Module.lib.fc_rbxsignals)
local EvoMM = require(Framework.Module.EvoMMWrapper)

local Connections = {Ended = false}
local CurrentGamemodeBaseScript = GamemodeService2:GetGamemodeScript(GamemodeService2.DefaultGamemode)
local CurrentGamemodeScript

--@summary Ran when the first player joins
function Init(player)
    local gmScript = CurrentGamemodeBaseScript
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
    Connections.Ended = gmScript:WaitForChild("Events"):WaitForChild("Ended").Event:Once(function(restart: boolean)
        Stop(restart)
    end)
    if CurrentGamemodeScript then
        CurrentGamemodeScript:Destroy()
    end
    CurrentGamemodeScript = gmScript
    if CurrentGamemodeBaseScript.Name ~= "1v1" then
        EvoMM:StartQueueService({"1v1"})
    end
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