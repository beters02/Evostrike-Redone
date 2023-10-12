local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Replicate = ReplicatedStorage.Services.AbilityService.Events.Replicate
local AbilityObjects = Framework.Service.AbilityService.Ability.HEGrenade.Assets
local EvoPlayer = require(Framework.Module.shared.Modules.EvoPlayer)
local Caster = require(Framework.Service.AbilityService.Caster)
local ScorchMark = Framework.Service.WeaponService.ServiceAssets.Models.ScorchMark

local HEGrenade = {
    Configuration = {
        -- data
        name = "HEGrenade",
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

        -- he grenade specific
        popLength = 2,
        maxDamage = 130,
        minDamage = 10,
        damageRadius = 35,
        radiusHeight = 3,
        damageSlow = -2.6,
        damageSlowLength = 1,
        velocitySlowMultPerInterval = 0.9, -- grenade velocity slow
        velocitySlowIntervalSec = 0.1,
        velocityMinimum = 0.5,
        glowFadeIn = 0.1,
        glowLength = 0.4,
        glowFadeOut = 2,
        dustLength = 4,
        dustFadeOut = 2,

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

Caster.new(HEGrenade)
if RunService:IsClient() then
    HEGrenade.popbindable = Instance.new("BindableEvent", AbilityObjects.Parent)
end

--@summary Required Grenade Function FireGrenade
function HEGrenade:FireGrenadePost(_, _, _, _, thrower, grenade)
    task.delay(self.Options.popLength, function()
        if HEGrenade.touchedConn then
            HEGrenade.touchedConn:Disconnect()
            HEGrenade.touchedConn = nil
        end
        if HEGrenade.slowTimeConn then
            HEGrenade.slowTimeConn:Disconnect()
            HEGrenade.slowTimeConn = nil
        end
        if not thrower then
            -- only fire this event if there is not a thrower variable, which means that the thrower is the LocalPlayer
            HEGrenade.popbindable:Fire()
        end
        task.delay(0.05, function()
            grenade:Destroy()
        end)
    end)
end

--@summary Required Grenade Function RayHit
-- grenadeClassObject, casterPlayer, caster, result, velocity, behavior, playerLookNormal)
function HEGrenade.RayHit(_, _, _, result, velocity, grenade)

    HEGrenade.currentGrenadeObject = grenade
    local isOwner = grenade:GetAttribute("IsOwner")
	local normal = result.Normal
	local reflected = velocity - 2 * velocity:Dot(normal) * normal
    grenade.CanCollide = true
    grenade.CollisionGroup = "Grenades"
    grenade.Velocity = reflected * 0.3

    Sound.Sounds("PlayClone", AbilityObjects.Sounds.Hit:GetChildren(), grenade)

    local function setvel(touched)
        local newMagnitude = grenade.Velocity.Magnitude * (touched and 0.8 or HEGrenade.Configuration.velocitySlowMultPerInterval)

        if newMagnitude < HEGrenade.Configuration.velocityMinimum then
            grenade.Anchored = true

            -- connect slowtime/touched in correct order
            if touched then
                HEGrenade.slowTimeConn:Disconnect()
                HEGrenade.touchedConn:Disconnect()
            else
                HEGrenade.touchedConn:Disconnect()
                HEGrenade.slowTimeConn:Disconnect()
            end
        end

        grenade.Velocity = grenade.Velocity.Unit * newMagnitude
    end

    local isInitialTouch = true
    local slowTime = false
    local _time = 0
    HEGrenade.touchedConn = grenade.Touched:Connect(function()
        if isInitialTouch then
            isInitialTouch = false
            return
        end
        Sound.Sounds("PlayClone", AbilityObjects.Sounds.Hit:GetChildren(), grenade)
        setvel(true)
        if not slowTime then
            slowTime = true
            HEGrenade.slowTimeConn = RunService.RenderStepped:Connect(function(dt)
                _time += dt
                if _time >= HEGrenade.Configuration.velocitySlowIntervalSec then
                    _time -= HEGrenade.Configuration.velocitySlowIntervalSec
                    setvel(false)
                end
            end)
        end
    end)
    
    if isOwner then
        -- Send remote server request once popbindable has fired
        HEGrenade.popbindable.Event:Once(function()
            Replicate:FireServer("HEGrenadeServerPop", grenade.Position)
        end)
    end

    return
end

--@summary Pop the Grenade on the Server
function HEGrenade.ServerPop(position)
    if RunService:IsClient() then return end

    local _explosion = AbilityObjects.Models.ExplosionPart:Clone()
    _explosion.Anchored = true
    _explosion.Parent = workspace
    _explosion.CFrame = CFrame.new(position)

    task.spawn(function()
        Sound.Sounds("PlayClone", AbilityObjects.Sounds.Explode:GetChildren(), _explosion)
        local scorchMarkResult = workspace:Raycast(position, position.Unit * Vector3.new(0,-1,0) * HEGrenade.Configuration.damageRadius, RaycastParams.new())
        if scorchMarkResult then
            local scorchMark = ScorchMark:Clone()
            scorchMark.Parent = workspace.Temp
            local cFrame = CFrame.new(scorchMarkResult.Position, scorchMarkResult.Position + scorchMarkResult.Normal)
            scorchMark.CFrame = cFrame
            scorchMark.Anchored = true
            scorchMark.CanCollide = false
            for _, v in pairs(scorchMark:GetChildren()) do
                TweenService:Create(v, TweenInfo.new(HEGrenade.Configuration.glowFadeIn), {Transparency = 0}):Play()
            end
            local _glowot = TweenService:Create(scorchMark.Glow, TweenInfo.new(HEGrenade.Configuration.glowFadeOut), {Transparency = 1})
            local _dustot = TweenService:Create(scorchMark.ScorchMark, TweenInfo.new(HEGrenade.Configuration.glowFadeOut), {Transparency = 1})
            task.delay(HEGrenade.Configuration.glowFadeIn + HEGrenade.Configuration.glowLength, function()
                _glowot:Play()
            end)
            task.delay(HEGrenade.Configuration.dustLength + HEGrenade.Configuration.glowFadeIn, function()
                _dustot:Play()
                _dustot.Completed:Once(function()
                    _glowot:Destroy()
                    _dustot:Destroy()
                    scorchMark:Destroy()
                end)
            end)
        end
    end)

    task.wait()

    for _, plr in pairs(Players:GetPlayers()) do
        if not plr.Character or plr.Character.Humanoid.Health <= 0 then continue end
        local distance = (plr.Character.PrimaryPart.Position - position).Magnitude
        local radius = HEGrenade.Configuration.damageRadius + HEGrenade.Configuration.radiusHeight
        if distance <= radius then
            plr.Character:SetAttribute("lastHitPart", "Torso")
            EvoPlayer:TakeDamage(plr.Character, math.clamp(((radius - distance)/radius) * HEGrenade.Configuration.maxDamage, HEGrenade.Configuration.minDamage, HEGrenade.Configuration.maxDamage))
        end
    end

    for _, v in pairs(_explosion:GetChildren()) do
        if not v:IsA("ParticleEmitter") then continue end
        v.Rate = v.EmitCount.Value
        task.delay(0.1, function()
            v.Rate = 0
        end)
    end

    Debris:AddItem(_explosion, 5)
end

return HEGrenade