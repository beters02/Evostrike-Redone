local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AbilityObjects = ReplicatedStorage:WaitForChild("ability"):WaitForChild("obj"):WaitForChild("Molly")

local HEGrenade = {

    -- grenade settings
    isGrenade = true,
    acceleration = 10,
    speed = 150,
    gravityModifier = 0.5,
    startHeight = 2,
    explodeLength = 1.2,
    maxDamage = 80,
    damageFalloffPerMeter = 1,
    damageFalloffDistance = {Min = 1, Max = 6},

    -- genral settings
    cooldownLength = 3,
    uses = 100,

    -- data settings
    abilityName = "HEGrenade",
    inventorySlot = "secondary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
    remoteEvent = nil,
}

--[[
    Use
]]

function HEGrenade:Use()

    -- long flash does CanUse on the server via remoteFunction: ThrowGrenade
    local hit = HEGrenade.player:GetMouse().Hit
    local used = HEGrenade.remoteFunction:InvokeServer("ThrowGrenade", hit)

    -- update client uses
    if used then
        self.uses -= 1
    end
end

return HEGrenade