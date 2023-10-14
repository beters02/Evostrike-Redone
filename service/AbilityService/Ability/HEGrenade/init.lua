--local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local AbilityObjects = Framework.Service.AbilityService.Ability.HEGrenade.Assets
local EvoPlayer = require(Framework.Module.shared.Modules.EvoPlayer)
local ScorchMark = Framework.Service.WeaponService.ServiceAssets.Models.ScorchMark
local Debris = game:GetService("Debris")
local ConnectionsLib = require(Framework.Module.lib.fc_rbxsignals)

local HEGrenade = {
    Options = {
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

--@server
function HEGrenade:FireGrenadePost(_, _, _, grenade)
    self.PopBindable = self.PopBindable or Instance.new("BindableEvent", script)
    game:GetService("CollectionService"):AddTag(grenade, "DestroyOnPlayerDied_" .. self.Player.Name)
    self.Grenade = grenade
    self:ConnectPop()
    task.delay(self.Options.popLength, function()
        self.PopBindable:Fire()
    end)
end

--@server Required Grenade Function RayHit
function HEGrenade:RayHit(_, result, velocity, grenade)
	local normal = result.Normal
	local reflected = velocity - 2 * velocity:Dot(normal) * normal
    grenade.CanCollide = true
    grenade.CollisionGroup = "Grenades"
    grenade.Velocity = reflected * 0.3
    Sound.Sounds("PlayClone", AbilityObjects.Sounds.Hit:GetChildren(), grenade)
    self:ConnectGrenadeHit(grenade)
    return
end

--@server
function HEGrenade:Pop(position)
    local _explosion = AbilityObjects.Models.ExplosionPart:Clone()
    _explosion.Anchored = true
    _explosion.Parent = workspace
    _explosion.CFrame = CFrame.new(position)

    task.spawn(function()
        Sound.Sounds("PlayClone", AbilityObjects.Sounds.Explode:GetChildren(), _explosion)
        local scorchMarkResult = workspace:Raycast(position, position.Unit * Vector3.new(0,-1,0) * HEGrenade.Options.damageRadius, RaycastParams.new())
        if scorchMarkResult then
            local scorchMark = ScorchMark:Clone()
            scorchMark.Parent = workspace.Temp
            local cFrame = CFrame.new(scorchMarkResult.Position, scorchMarkResult.Position + scorchMarkResult.Normal)
            scorchMark.CFrame = cFrame
            scorchMark.Anchored = true
            scorchMark.CanCollide = false
            for _, v in pairs(scorchMark:GetChildren()) do
                TweenService:Create(v, TweenInfo.new(HEGrenade.Options.glowFadeIn), {Transparency = 0}):Play()
            end
            local _glowot = TweenService:Create(scorchMark.Glow, TweenInfo.new(HEGrenade.Options.glowFadeOut), {Transparency = 1})
            local _dustot = TweenService:Create(scorchMark.ScorchMark, TweenInfo.new(HEGrenade.Options.glowFadeOut), {Transparency = 1})
            task.delay(HEGrenade.Options.glowFadeIn + HEGrenade.Options.glowLength, function()
                _glowot:Play()
            end)
            task.delay(HEGrenade.Options.dustLength + HEGrenade.Options.glowFadeIn, function()
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
        local radius = HEGrenade.Options.damageRadius + HEGrenade.Options.radiusHeight
        if distance <= radius then
            plr.Character:SetAttribute("lastHitPart", "Torso")
            EvoPlayer:TakeDamage(plr.Character, math.clamp(((radius - distance)/radius) * HEGrenade.Options.maxDamage, HEGrenade.Options.minDamage, HEGrenade.Options.maxDamage))
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

local function setvel(grenade, touched)
    local newMagnitude = grenade.Velocity.Magnitude * (touched and 0.8 or HEGrenade.Options.velocitySlowMultPerInterval)

    if newMagnitude < HEGrenade.Options.velocityMinimum then
        grenade.Anchored = true
        return
    end

    grenade.Velocity = grenade.Velocity.Unit * newMagnitude
end

function HEGrenade:ConnectPop()
    self.PopBindable.Event:Once(function()
        self:DisconnectGrenade()
        self:Pop(self.Grenade.CFrame.Position)
        self.Grenade:Destroy()
    end)
end

function HEGrenade:ConnectGrenadeHit(grenade)
    local isInitialTouch = true
    local hasInitSlowTime = false
    grenade.Anchored = false
    self.Connections = ConnectionsLib.TableConnect(self.Connections, "Touched", grenade.Touched:Connect(function()
        if isInitialTouch then
            isInitialTouch = false
            return
        end

        Sound.Sounds("PlayClone", AbilityObjects.Sounds.Hit:GetChildren(), grenade)
        setvel(grenade, true)

        if not hasInitSlowTime then
            hasInitSlowTime = true
            self:ConnectGrenadeSlow(grenade)
        end
    end))
end

function HEGrenade:ConnectGrenadeSlow(grenade)
    local _time = 0
    self.Connections = ConnectionsLib.TableConnect(self.Connections, "SlowTime", RunService.Heartbeat:Connect(function(dt)
        _time += dt
        if _time >= HEGrenade.Options.velocitySlowIntervalSec then
            _time -= HEGrenade.Options.velocitySlowIntervalSec
            setvel(grenade)
        end
    end))
end

function HEGrenade:DisconnectGrenade()
    ConnectionsLib.DisconnectAllIn(self.Connections)
end

function HEGrenade:LengthChanged(_, lastPoint, direction, length, velocity, bullet) -- cast, lastPoint, direction, length, velocity, bullet
    if bullet then
        local bulletLength = bullet.Size.Z/2
        local offset = CFrame.new(0, 0, -(length - bulletLength))
        bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
    end
end

return HEGrenade