local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(Framework.shfc_strings.Location)
local SharedAbilityRF = ReplicatedStorage.ability.remote.sharedAbilityRF
local States = require(Framework.shm_states.Location)
local PlayerData = require(Framework.shm_clientPlayerData.Location)

local player = game:GetService("Players").LocalPlayer
local key
local keyCode

-- create ability class for functions
local abilityName = string.gsub(script.Parent.Parent.Name, "AbilityFolder_", "")
local abilityClassModule, baseAbilityClassModule = SharedAbilityRF:InvokeServer("Class", abilityName)
local ability = require(baseAbilityClassModule).new(abilityClassModule)
local abilityObjects = ReplicatedStorage.ability.obj:WaitForChild(abilityName)
ability.abilityObjects = abilityObjects

-- define some ability var
local useKeyName = "Key_" .. Strings.firstToUpper(ability.inventorySlot) .. "Ability"
local abilityRemotes = script.Parent.Parent.Remotes
ability.remoteFunction = abilityRemotes.AbilityRemoteFunction
ability.remoteEvent = abilityRemotes.AbilityRemoteEvent
ability.bindableEvent = abilityRemotes.AbilityBindableEvent

-- init keycode
local keypath = "options.keybinds." .. ability.inventorySlot .. "Ability"
keyCode = PlayerData:Get(keypath)

-- listen for changed
PlayerData:Changed(keypath, function(newValue)
    keyCode = newValue
    ability.key = keyCode
end)

-- init HUD GUI
local abilityFrame
local abilityIcon

local abilityBar = player.PlayerGui:WaitForChild("HUD").AbilityBar
abilityFrame = abilityBar:WaitForChild(Strings.firstToUpper(ability.inventorySlot))

ability.frame = abilityFrame
abilityFrame.Key.Text = Strings.convertFullNumberStringToNumberString(keyCode)
ability.key = keyCode

abilityIcon = abilityFrame:WaitForChild("IconImage")
abilityIcon.Image = abilityObjects.Images.Icon.Texture
abilityIcon.ImageTransparency = 0
abilityIcon.ImageColor3 = abilityFrame:GetAttribute("EquippedColor")

game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathBE").Event:Connect(function()
    abilityIcon.ImageTransparency = 1
end)

-- init animations
ability._animations = {}
if abilityObjects:FindFirstChild("Animations") then
    for i, v in pairs(abilityObjects.Animations:GetChildren()) do
        ability._animations[string.lower(v.Name)] = workspace.CurrentCamera.viewModel.AnimationController:LoadAnimation(v)
    end
end

-- init sounds
ability._sounds = abilityObjects:WaitForChild("Sounds")

-- init state variables
States.SetStateVariable("PlayerActions", "grenadeThrowing", false)

-- connect
local debounce = false
UserInputService.InputBegan:Connect(function(input, gp)
    if debounce then return end
    if (string.match(keyCode, "Mouse") and input.UserInputType == Enum.UserInputType[keyCode]) or input.KeyCode == Enum.KeyCode[keyCode] then
        if ability.uses <= 0 or ability.cooldown then return end
        if ability.isGrenade then
            if States.GetStateVariable("PlayerActions", "shooting") then return end
            if States.GetStateVariable("PlayerActions", "weaponEquipping") then return end
        end
        
        debounce = true
        task.delay(0.1, function() debounce = false end)
        task.wait()
       
        -- start cooldown
        ability.cooldown = true
        ability:StartClientCooldown()
        
        -- use ability
        ability:Use()
    end
end)

ability.remoteEvent.OnClientEvent:Connect(function(action, ...)
    if action == "CooldownFinished" then
        --ability.cooldown = false
    end
end)

script:WaitForChild("communicate").Event:Connect(function(action)
    if action == "StopThrowAnimation" then
        print('Stopping')
        if not ability._animations.throw.IsPlaying then return end
        ability._animations.throw:Stop(0.1)
    end
end)