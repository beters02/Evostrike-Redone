local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityModuleLocation = game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("Ability")
local Classes = AbilityModuleLocation.Class
local GetRemote = ReplicatedStorage.Remotes.Ability.Get

local GetFunctions = {
    Class = function(abilityName)
        if abilityName == "Base" then return end
        local class = Classes:FindFirstChild(abilityName)
        if not class then return end

        class = class:Clone()
        class.Parent = ReplicatedStorage

        local baseClass = Classes.Base:Clone()
        baseClass.Parent = ReplicatedStorage

        return class, baseClass
    end
}

local function Get(player, action, ...)
    local func = GetFunctions[action]
    if not func then return end
    return func(...)
end

GetRemote.OnServerInvoke = Get