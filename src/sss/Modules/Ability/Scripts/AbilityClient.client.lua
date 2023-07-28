local UserInputService = game:GetService("UserInputService")
local Scripts = game:GetService("ReplicatedStorage"):WaitForChild("Scripts")
local Strings = require(Scripts:WaitForChild("Libraries"):WaitForChild("Strings"))
local PlayerOptions = require(Scripts:WaitForChild("Modules"):WaitForChild("PlayerOptions"))

-- create ability class for functions
local abilityName = string.gsub(script.Parent.Parent.Name, "AbilityFolder_", "")
local abilityClassModule, baseAbilityClassModule = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Ability"):WaitForChild("Get"):InvokeServer("Class", abilityName)
local ability = require(baseAbilityClassModule).new(abilityClassModule)

-- define some ability var
local useKeyName = "Key_" .. Strings.firstToUpper(ability.inventorySlot) .. "Ability"
local abilityRemotes = script.Parent.Parent.Remotes
local abilityRemoteFunction = abilityRemotes.AbilityRemoteFunction
ability.remoteFunction = abilityRemoteFunction

UserInputService.InputBegan:Connect(function(input, gp)
    local key = PlayerOptions[useKeyName]
    local keyCode = key and Enum.KeyCode[key]
    if not keyCode then return end

    if input.KeyCode == keyCode then
        if ability.uses <= 0 then return end
        
        ability:Use()
    end
end)