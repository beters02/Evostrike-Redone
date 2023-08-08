local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local GetRemote = ReplicatedStorage.Remotes.Ability.Get
local RunService = game:GetService("RunService")
local AbilityFunc = require(Framework.ReplicatedStorage.Libraries.SharedAbilityFunctions)

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera
local grenadeEvent = ReplicatedStorage.Remotes.Ability.Grenade :: RemoteEvent
local storedCasters = {} -- abilityName = caster

--[[
    Client Grenade Caster Handling
]]

-- If an Ability is a grenade, we will want to initiate the caster using the ability's settings.
local function initClientGrenadeCaster(abilityOptions, abilityObjects)
    local abname = abilityOptions.abilityName

    -- if a caster exists for the ability, do not create a new one
    if storedCasters[abname] then return storedCasters[abname] end

    local caster, casbeh = AbilityFunc.InitCaster(character, abilityOptions, abilityObjects)
    storedCasters[abname] = {caster, casbeh}
end

local serverGrenadeDebug = false
local function fireClientGrenadeCaster(fromPlayer, serverGrenade, mouseHit, abilityOptions)
    local stored = storedCasters[abilityOptions.abilityName]
    local caster, casbeh = stored[1], stored[2]

    if serverGrenadeDebug then
        serverGrenade.Size *= 1.1
        serverGrenade.Color = Color3.new(255, 0, 0)
        serverGrenade.Transparency = 0
    else
        serverGrenade:Destroy()
    end

    AbilityFunc.FireCaster(fromPlayer, mouseHit, caster, casbeh, abilityOptions)
end

--[[
    LongFlash
]]

local function canSee(part)
    local pos = part.Position
    local vector, inViewport = camera:WorldToViewportPoint(pos)
    local onScreen = inViewport and vector.Z > 0
    if onScreen then
        return true
    end
    return false
end

--[[
    Get
]]

GetRemote.OnClientInvoke = function(action, ...)
    if action == "CanSee" then
        return canSee(...)
    end
end

--[[
    Grenade Connections
]]

grenadeEvent.OnClientEvent:Connect(function(action, ...)
    if action == "Create" then
        initClientGrenadeCaster(...)
    elseif action == "Fire" then
        fireClientGrenadeCaster(...)
    end
end)