local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local GamemodeHUDEvents = Framework.Service.GamemodeService2.Events.HUD
local PlayerDiedHUDEvent = GamemodeHUDEvents.PlayerDied
local ChangeTopBarHUDEvent = GamemodeHUDEvents.ChangeTopBar

local GM1v1 = {connections = {}, objects = {}}
local PlayerDied = require(script:WaitForChild("PlayerDied"))
local TopBar = require(script:WaitForChild("TopBar"))

function GM1v1.Enable(enemy, timeLeft)
    GM1v1.objects.TopBar = TopBar.init(game.Players.LocalPlayer, enemy)
    if timeLeft then
        GM1v1.objects.TopBar:StartTimer(timeLeft)
    end
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