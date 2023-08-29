local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AbilityObjects = ReplicatedStorage:WaitForChild("ability"):WaitForChild("obj"):WaitForChild("Molly")
local Sound = require(Framework.shm_sound.Location)
local States = require(Framework.shm_states.Location)

local Molly = {

    -- grenade settings
    isGrenade = true,
    grenadeThrowDelay = 0.2,
    usingDelay = 1, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time
    acceleration = 10,
    speed = 150,
    gravityModifier = 0.5,
    startHeight = 2,

    -- molotov settings
    mollyLength = 3,
    damageInterval = 0.4,
    damagePerInterval = 15,

    -- genral settings
    cooldownLength = 10,
    uses = 100,

    -- absr = Absolute Value Random
    -- rtabsr = Random to Absolute Value Random
    useCameraRecoil = {
        downDelay = 0.07,

        up = 0.03,
        side = 0.011,
        shake = "0.015-0.035rtabsr",

        speed = 4,
        force = 60,
        damp = 4,
        mass = 9
    },

    -- data settings
    abilityName = "Molly",
    inventorySlot = "secondary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
    remoteEvent = nil,
}

return Molly