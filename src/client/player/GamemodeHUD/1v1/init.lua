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

-- Init function called before game is started.
function GM1v1.Init()
    print('Yuh!')
    GM1v1.objects.WaitingForPlayers = WaitingForPlayers.init()
end

-- Called after game is started.
function GM1v1.Enable(enemy)
    print('Yuh yuh!')
    GM1v1.objects.WaitingForPlayers:Disable()
    GM1v1.objects.TopBar = TopBar.init(game.Players.LocalPlayer, enemy)
    print('Top Bar Init!')
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

return GM1v1