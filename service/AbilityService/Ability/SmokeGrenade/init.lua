local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local TweenService = game:GetService("TweenService")
local Replicate = ReplicatedStorage.Services.AbilityService.Events.Replicate
local AbilityObjects = Framework.Service.AbilityService.Ability.SmokeGrenade.Assets
local Caster = require(Framework.Service.AbilityService.Caster)

local SmokeGrenade = {
    Configuration = {
        -- data
        name = "SmokeGrenade",
        inventorySlot = "secondary",
        isGrenade = true,
        
        -- general
        cooldownLength = 10,
        uses = 100,
        usingDelay = 1, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time

        -- grenade
        grenadeThrowDelay = 0.36,
        acceleration = 10,
        speed = 150,
        gravityModifier = 0.5,
        startHeight = 2,

        -- animation / holding
        clientGrenadeSize = Vector3.new(0.328, 1.047, 0.359),
        grenadeVMOffsetCFrame = false, -- if you have a custom animation already, set this to false
        throwAnimFadeTime = 0.18,
        throwFinishSpringShove = Vector3.new(-0.4, -0.5, 0.2),

        -- smoke grenade specific
        smokeLengthBeforePop = 1.8,
        smokeFadeInLength = 0.8,
        smokeLength = 4,
        smokeFadeOutLength = 1,
        smokeBubbleStartSizeModifier = 0.3,
        smokeBubbleStartTransparency = 0.7,
        smokeGrenadeVelocitySlowMultPerInterval = 0.7,
        smokeGrenadeVelocitySlowIntervalSec = 0.1,
        smokeGrenadeVelocityMinimum = 0.5,

        -- absr = Absolute Value Random
        -- rtabsr = Random to Absolute Value Random
        useCameraRecoil = {
            downDelay = 0.07,

            up = 0.03,
            side = 0.011,
            shake = "0.015-0.035rtabsr",

            speed = 4,
            force = 60,
            damp = 4,
            mass = 9
        }
    },
    AbilityObjects = AbilityObjects
}

Caster.new(SmokeGrenade)
if RunService:IsClient() then
    SmokeGrenade.popbindable = Instance.new("BindableEvent", AbilityObjects.Parent)
end

--@override
function SmokeGrenade:FireGrenadePost(_, _, _, _, thrower, grenade)
    task.delay(self.Options.smokeLengthBeforePop, function()
        if SmokeGrenade.touchedConn then
            SmokeGrenade.touchedConn:Disconnect()
            SmokeGrenade.touchedConn = nil
        end
        if SmokeGrenade.slowTimeConn then
            SmokeGrenade.slowTimeConn:Disconnect()
            SmokeGrenade.slowTimeConn = nil
        end
        Debris:AddItem(grenade, 3)
        grenade.Transparency = 1
        if not thrower then
            -- only fire this event if there is not a thrower variable, which means that the thrower is the LocalPlayer
            SmokeGrenade.popbindable:Fire()
        end
    end)
end

--@summary Required Grenade Function RayHit
-- class, casterPlayer, casterThrower, result, velocity, grenade
function SmokeGrenade.RayHit(_, _, _, result, velocity, grenade)
    local isOwner = grenade:GetAttribute("IsOwner")
	local normal = result.Normal
	local reflected = velocity - 2 * velocity:Dot(normal) * normal
    grenade.CanCollide = true
    grenade.CollisionGroup = "Grenades"
    grenade.Velocity = reflected * 0.3

    Sound.PlayClone(AbilityObjects.Sounds.Hit, grenade)
    local Throwing = Sound.PlayClone(AbilityObjects.Sounds.Throwing, grenade)
    task.delay(SmokeGrenade.Configuration.smokeLengthBeforePop, function()
        Throwing:Destroy()
    end)

    local function setvel(touched)
        local newMagnitude = grenade.Velocity.Magnitude * (touched and 0.8 or SmokeGrenade.Configuration.smokeGrenadeVelocitySlowMultPerInterval)

        if newMagnitude < SmokeGrenade.Configuration.smokeGrenadeVelocityMinimum then
            grenade.Anchored = true

            -- connect slowtime/touched in correct order
            if touched then
                SmokeGrenade.slowTimeConn:Disconnect()
                SmokeGrenade.touchedConn:Disconnect()
            else
                SmokeGrenade.touchedConn:Disconnect()
                SmokeGrenade.slowTimeConn:Disconnect()
            end
        end

        grenade.Velocity = grenade.Velocity.Unit * newMagnitude
    end

    local isInitialTouch = true
    SmokeGrenade.touchedConn = grenade.Touched:Connect(function()
        if isInitialTouch then
            isInitialTouch = false
            return
        end
        Sound.PlayClone(AbilityObjects.Sounds.Hit, grenade)
        setvel(true)
    end)

    local _time = 0
    SmokeGrenade.slowTimeConn = RunService.RenderStepped:Connect(function(dt)
        _time += dt
        if _time >= SmokeGrenade.Configuration.smokeGrenadeVelocitySlowIntervalSec then
            _time -= SmokeGrenade.Configuration.smokeGrenadeVelocitySlowIntervalSec
            setvel(false)
        end
    end)

    if isOwner then
        -- Send remote server request once popbindable has fired
        SmokeGrenade.popbindable.Event:Wait()
        Replicate:FireServer("SmokeGrenadeServerPop", grenade.Position)
    end

    return
end

function SmokeGrenade.CreateSmokeBubble(pos)
    local bubble = AbilityObjects.Models.SmokeBubble:Clone()
    local bubbleSize = bubble.Size
    bubble.Size *= SmokeGrenade.Configuration.smokeBubbleStartSizeModifier
    bubble.Anchored = true
    bubble.CanCollide = false
    bubble.CollisionGroup = "BulletAndMovementIgnore"
    bubble:SetAttribute("SmokeLength", SmokeGrenade.Configuration.smokeLength)
    bubble:SetAttribute("SmokeFadeInLength", SmokeGrenade.Configuration.smokeFadeInLength)
    bubble:SetAttribute("SmokeFadeOutLength", SmokeGrenade.Configuration.smokeFadeOutLength)
    bubble.Parent = workspace.Temp
    bubble.CFrame = CFrame.new(pos)

    Sound.PlayClone(AbilityObjects.Sounds.Pop, bubble)

    TweenService:Create(bubble, TweenInfo.new(SmokeGrenade.Configuration.smokeFadeInLength), {Size = bubbleSize, Transparency = 0}):Play()
    local out = TweenService:Create(bubble, TweenInfo.new(SmokeGrenade.Configuration.smokeFadeOutLength), {Size = bubbleSize * SmokeGrenade.Configuration.smokeBubbleStartSizeModifier, Transparency = 1})
    task.delay(SmokeGrenade.Configuration.smokeLength, function()
        pcall(function() bubble.ParticleEmitter.Enabled = false bubble.SmokeT.Enabled = false bubble.SmokeB.Enabled = false end)
        out:Play()
        out.Completed:Wait()
        Debris:AddItem(bubble, 3)
    end)
end

--@summary Pop the SmokeGrenade on the Server
function SmokeGrenade.ServerPop(position)
    if RunService:IsClient() then return end
    SmokeGrenade.CreateSmokeBubble(position)
end

return SmokeGrenade