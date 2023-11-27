local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local GamemodeHUDEvents = Framework.Service.GamemodeService2.Events.HUD
local SetGamemodeHUDEvent = GamemodeHUDEvents.SetGamemodeHUD

local player = Players.LocalPlayer
local current = false

SetGamemodeHUDEvent.OnClientEvent:Connect(function(gamemode, ...)
    if current then
        current.Disable()
    end
    current = require(script[gamemode])
    current.Enable(...)
end)