local HEGrenade = {
    name = "HEGrenade",
    isGrenade = true,

    -- grenade settings
    grenadeThrowDelay = 0.2,
    usingDelay = 1, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time
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

return HEGrenade