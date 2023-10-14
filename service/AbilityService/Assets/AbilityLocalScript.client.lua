local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Framework = require(game.ReplicatedStorage.Framework)
local PlayerData = require(Framework.Module.shared.PlayerData.m_clientPlayerData)
local Strings = require(Framework.Module.lib.fc_strings)
local UIState = require(Framework.Module.m_states).State("UI")
local Bindable = Framework.Service.AbilityService.Events.BindableEvent
local FastCast = require(Framework.Module.lib.c_fastcast)

local Const = {KeyPath = false, Frame = false, Icon = false, Module = script.Parent:WaitForChild("ModuleObject").Value}
local Ability = require(Framework.Service.AbilityService.Ability).new(game.Players.LocalPlayer, Const.Module)
local Var = {Uses = Ability.Options.uses, OnCooldown = false, Key = false}
local RemoteFunction = script.Parent:WaitForChild("Events"):WaitForChild("RemoteFunction")
local RemoteEvent = script.Parent.Events.RemoteEvent
Ability.RemoteFunction = RemoteFunction
Ability.RemoteEvent = RemoteEvent

local function Cooldown()
    Var.OnCooldown = true
    return task.spawn(function()
        SetIconColorEquipped(false)

        for i = Ability.Options.cooldownLength, 0, -1 do
            if i == 0 then
                Var.OnCooldown = false
                Const.Frame.Key.Text = Strings.convertFullNumberStringToNumberString(Var.Key)
                SetIconColorEquipped(true)
                break
            end

            Const.Frame.Key.Text = tostring(i)
            task.wait(1)
        end
    end)
end

local function Use()
    if Var.Uses <= 0 or Var.OnCooldown then
        return
    end
    Cooldown()
    Ability:Use()
end

function InputBegan(input, gp)
    if gp or UIState:hasOpenUI() or Ability.Player:GetAttribute("Typing") then
        return
    end
    if input.KeyCode == Enum.KeyCode[Var.Key] then
        Use()
    end
end

function InitKeybinds()
    Const.KeyPath = "options.keybinds." .. Ability.Options.inventorySlot .. "Ability"
    Var.Key = PlayerData:Get(Const.KeyPath)
    Ability.Key = Var.Key
end

function InitHud()
    Const.Frame = Players.LocalPlayer.PlayerGui:WaitForChild("HUD").AbilityBar:WaitForChild(Strings.firstToUpper(Ability.Options.inventorySlot))
    Const.Frame.Key.Text = Strings.convertFullNumberStringToNumberString(Var.Key)
    Const.Icon = Const.Frame:WaitForChild("IconImage")
    Const.Icon.Image = Const.Module.Assets.Images.Icon.Image
    Const.Icon.ImageTransparency = 0
    Const.Icon.ImageColor3 = Const.Frame:GetAttribute("EquippedColor")
    Const.Icon.Visible = true
    Const.Frame.Visible = true
    Ability.Frame = Const.Frame
    Ability.Icon = Const.Icon
end

function Connect()
    UserInputService.InputBegan:Connect(InputBegan)
    PlayerData:Changed(Const.KeyPath, function(newValue)
        Var.Key = newValue
        Ability.Key = newValue
        Ability.Frame.Key.Text = Strings.convertFullNumberStringToNumberString(Var.Key)
    end)
    Bindable.Event:Connect(function(action, fadeTime)
        if action == "StopAnimations" then
            for _, v in pairs(Ability.Animations) do
                v:Stop(fadeTime)
            end
        end
    end)
end

function SetIconColorEquipped(equipped: boolean)
    Const.Frame.IconImage.ImageColor3 = equipped and Const.Frame:GetAttribute("EquippedColor") or Const.Frame:GetAttribute("UnequippedColor")
end

function Init()
    InitKeybinds()
    InitHud()
    Connect()
end

Init()