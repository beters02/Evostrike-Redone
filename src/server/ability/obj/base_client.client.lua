local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(Framework.shfc_strings.Location)
local SharedAbilityRF = ReplicatedStorage.ability.remote.sharedAbilityRF
--local PlayerOptions = require(Scripts:WaitForChild("Modules"):WaitForChild("PlayerOptions"))

local player = game:GetService("Players").LocalPlayer
local key
local keyCode

-- create ability class for functions
local abilityName = string.gsub(script.Parent.Parent.Name, "AbilityFolder_", "")
local abilityClassModule, baseAbilityClassModule = SharedAbilityRF:InvokeServer("Class", abilityName)
local ability = require(baseAbilityClassModule).new(abilityClassModule)

-- define some ability var
local useKeyName = "Key_" .. Strings.firstToUpper(ability.inventorySlot) .. "Ability"
local abilityRemotes = script.Parent.Parent.Remotes
ability.remoteFunction = abilityRemotes.AbilityRemoteFunction
ability.remoteEvent = abilityRemotes.AbilityRemoteEvent

--[[
	Init HUD GUI
]]

local keys = {primary = "F", secondary = "V"}
ability.key = keys[ability.inventorySlot]

local abilityBar = player.PlayerGui:WaitForChild("HUD").AbilityBar
local abilityFrame = abilityBar:WaitForChild(Strings.firstToUpper(ability.inventorySlot))
abilityFrame.Visible = true

ability.frame = abilityFrame
abilityFrame.Key.Text = ability.key

UserInputService.InputBegan:Connect(function(input, gp)
    --key = PlayerOptions[useKeyName]
    keyCode = ability.key and Enum.KeyCode[ability.key]
    if not keyCode then return end
    if input.KeyCode == keyCode then
        if ability.uses <= 0 then return end
        if ability.cooldown then return end
        

        ability:StartClientCooldown()
        ability:Use()
        print('used')
    end
end)

ability.remoteEvent.OnClientEvent:Connect(function(action, ...)
    if action == "CooldownFinished" then
        ability.cooldown = false
    end
end)