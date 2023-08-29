local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Classes = Framework.Ability.Location.Parent.class
local SharedAbilityRF = ReplicatedStorage:WaitForChild("ability").remote.sharedAbilityRF

local GetFunctions = {
    Class = function(abilityName)
        if abilityName == "Base" then return end
        local class = Classes:FindFirstChild(abilityName)
        if not class then return end

        class = class:Clone()
        class.Parent = ReplicatedStorage

        local baseClass = Classes.Base:Clone()
        baseClass.Parent = ReplicatedStorage

        local baseGrenadeClass = Classes.GrenadeBase:Clone()
        baseGrenadeClass.Parent = class

        game:GetService("Debris"):AddItem(class, 3)
        game:GetService("Debris"):AddItem(baseClass, 3)

        return class, baseClass
    end
}

local function Get(player, action, ...)
    local func = GetFunctions[action]
    if not func then return end
    return func(...)
end

SharedAbilityRF.OnServerInvoke = Get