local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local GamemodeHUDEvents = Framework.Service.GamemodeService2.Events.HUD
local PlayerDiedHUDEvent = GamemodeHUDEvents.PlayerDied
local ChangeTopBarHUDEvent = GamemodeHUDEvents.ChangeTopBar

local GM1v1 = {connections = {}, objects = {}}
local PlayerDied = require(script:WaitForChild("PlayerDied"))
local TopBar = require(script:WaitForChild("TopBar"))
local WaitingForPlayers = require(script:WaitForChild("WaitingForPlayers"))
local RoundOver = require(script:WaitForChild("RoundOver"))
local RoundStart = require(script:WaitForChild("RoundStart"))

-- Init function called before game is started.
function GM1v1.Init()
    GM1v1.objects.WaitingForPlayers = WaitingForPlayers.init()
end

-- Called after game is started.
function GM1v1.Enable(enemy)
    GM1v1.objects.WaitingForPlayers:Disable()
    GM1v1.objects.TopBar = TopBar.init(game.Players.LocalPlayer, enemy)
end

function GM1v1.StartTimer(length)
    GM1v1.objects.TopBar:StartTimer(length)
end

function GM1v1.ChangeScore(data)
    GM1v1.objects.TopBar:ChangeScore(data)
end

function GM1v1.ChangeRound(round)
    GM1v1.objects.TopBar:ChangeRound(round)
end

function GM1v1.Disable()
    GM1v1.Disconnect()
    GM1v1.ClearObjects()
end

function GM1v1.Disconnect()
    for _, v in pairs(GM1v1.connections) do
        v:Disconnect()
    end
    GM1v1.connections = {}
end

function GM1v1.ClearObjects()
    for _, v in pairs(GM1v1.objects) do
        v:Destroy()
    end
end

function GM1v1.RoundOver(winner, loser)
    GM1v1.objects.RoundOver = RoundOver.init(winner, loser)
end

function GM1v1.RoundStart()
    RoundStart.init()
end

return GM1v1