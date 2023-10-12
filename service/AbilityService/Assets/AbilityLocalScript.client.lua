local UserInputService = game:GetService("UserInputService")
local Framework = require(game.ReplicatedStorage.Framework)
local PlayerData = require(Framework.Module.shared.PlayerData.m_clientPlayerData)
local Strings = require(Framework.Module.lib.fc_strings)
local UIState = require(Framework.Module.m_states).State("UI")
local Bindable = Framework.Service.AbilityService.Events.BindableEvent
local FastCast = require(Framework.Module.lib.c_fastcast)

local Module = script.Parent:WaitForChild("ModuleObject").Value
local Ability = require(Framework.Service.AbilityService.Ability).new(game.Players.LocalPlayer, Module)
local Var = {Uses = Ability.Options.uses, OnCooldown = false, Key = false, KeyPath = false}
local RemoteFunction = script.Parent:WaitForChild("Events"):WaitForChild("RemoteFunction")
local RemoteEvent = script.Parent.Events.RemoteEvent
Ability.RemoteFunction = RemoteFunction
Ability.RemoteEvent = RemoteEvent

local function Use()
    if Var.Uses <= 0 or Var.OnCooldown then
        return
    end
    if Ability.Options.isGrenade then
        task.spawn(function()
            local serverGrenade = RemoteFunction:InvokeServer("FireGrenadeServer")
            Ability.ServerGrenade = serverGrenade
            serverGrenade.Transparency = 1
            for _, v in ipairs(serverGrenade:GetChildren()) do
                if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("Texture") then
                    v.Transparency = 1
                end
            end
        end)
    end
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
    Var.KeyPath = "options.keybinds." .. Ability.Options.inventorySlot .. "Ability"
    Var.Key = PlayerData:Get(Var.KeyPath)
    Ability.Key = Var.Key
    Ability.Frame.Key.Text = Strings.convertFullNumberStringToNumberString(Var.Key)
end

function InitCaster()
    local caster = FastCast.new()
    local castBeh = FastCast.newBehavior()

	castBeh.Acceleration = Vector3.new(0, -workspace.Gravity * Ability.Options.gravityModifier, 0)
	castBeh.AutoIgnoreContainer = false
	castBeh.CosmeticBulletContainer = workspace.Temp
	castBeh.CosmeticBulletTemplate = Module:WaitForChild("Assets").Models.Grenade
    castBeh.RaycastParams = Ability.Params
    caster.RayHit:Connect(function(...)
        Ability:RayHitCore(...)
    end) --function()
    --Ability.RayHit(casterThatFired, result, segmentVelocity, cosmeticBulletObject)
    caster.LengthChanged:Connect(Ability.LengthChanged)
    caster.CastTerminating:Connect(function()end)

    Ability.Caster = caster
    Ability.CastBehavior = castBeh
end

function Connect()
    PlayerData:Changed(Var.KeyPath, function(newValue)
        Var.Key = newValue
        Ability.Key = newValue
        Ability.Frame.Key.Text = Strings.convertFullNumberStringToNumberString(Var.Key)
    end)
    Bindable.Event:Connect(function(action, fadeTime)
        if action == "StopAnimations" then
            Ability:StopAnimations(fadeTime)
        end
    end)
end

function Init()
    InitKeybinds()

    if Ability.Options.isGrenade then
        InitCaster()
    end

    Connect()
    UserInputService.InputBegan:Connect(InputBegan)
end

