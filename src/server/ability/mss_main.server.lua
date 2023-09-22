local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Classes = ReplicatedStorage:WaitForChild("ability").class
local SharedAbilityRF = ReplicatedStorage:WaitForChild("ability").remote.sharedAbilityRF
local SharedAbilityRE = ReplicatedStorage.ability.remote.sharedAbilityRE
local Ability = require(Framework.Module.server.ability.pm_main)

local Molly = require(ReplicatedStorage.ability.class:WaitForChild("Molly"))
local LongFlash = require(ReplicatedStorage.ability.class:WaitForChild("LongFlash"))

ReplicatedStorage.ability.remote.replicate.OnServerEvent:Connect(function(player, action, ...)
    if action == "MollyServerExplode" then
        Molly.ServerExplode(...)
    elseif action == "LongFlashServerPop" then
        local pos, canSee = ...
        if canSee then
            LongFlash.AttemptBlindPlayer(player, pos, false)
        end
    end
end)

local GetFunctions = {
    Class = function(abilityName)
        if abilityName == "Base" then return end
        local class = Classes:FindFirstChild(abilityName)
        local clone = class:Clone()
        clone.Parent = ReplicatedStorage
        local baseClass = Classes.Base:Clone()
        baseClass.Parent = ReplicatedStorage
        local baseGrenadeClass = Classes.GrenadeBase:Clone()
        baseGrenadeClass.Parent = clone
        return clone, baseClass
    end
}

local function Get(player, action, ...)
    local func = GetFunctions[action]
    if not func then return end
    return func(...)
end

SharedAbilityRF.OnServerInvoke = Get

SharedAbilityRE.OnServerEvent:Connect(function(player, action, ...)
    if action == "Add" then
        Ability.Add(player, ...)
    end
end)