local UserInputService = game:GetService("UserInputService")
local Scripts = game:GetService("ReplicatedStorage"):WaitForChild("Scripts")
local Strings = require(Scripts:WaitForChild("Libraries"):WaitForChild("Strings"))
local PlayerOptions = require(Scripts:WaitForChild("Modules"):WaitForChild("PlayerOptions"))

local player = game:GetService("Players").LocalPlayer
local key
local keyCode

-- create ability class for functions
local abilityName = string.gsub(script.Parent.Parent.Name, "AbilityFolder_", "")
local abilityClassModule, baseAbilityClassModule = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Ability"):WaitForChild("Get"):InvokeServer("Class", abilityName)
local ability = require(baseAbilityClassModule).new(abilityClassModule)

-- define some ability var
local useKeyName = "Key_" .. Strings.firstToUpper(ability.inventorySlot) .. "Ability"
local abilityRemotes = script.Parent.Parent.Remotes
local abilityRemoteFunction = abilityRemotes.AbilityRemoteFunction
ability.remoteFunction = abilityRemoteFunction

--[[
	Init HUD GUI
]]

local abilityBar = player.PlayerGui:WaitForChild("HUD").AbilityBar
local abilityFrame = abilityBar:WaitForChild(Strings.firstToUpper(ability.inventorySlot))
abilityFrame.Visible = true

abilityFrame.Key.Text = PlayerOptions[useKeyName]

ability.frame = abilityFrame
ability.key = PlayerOptions[useKeyName]

UserInputService.InputBegan:Connect(function(input, gp)
    key = PlayerOptions[useKeyName]
    keyCode = key and Enum.KeyCode[key]
    if not keyCode then return end

    if input.KeyCode == keyCode then
        if ability.uses <= 0 then return end
        if ability.cooldown then return end
        
        ability:StartClientCooldown()
        ability:Use()
    end
end)