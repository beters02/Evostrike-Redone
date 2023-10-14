local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local TweenService = game:GetService("TweenService")
local ConnectionsLib = require(Framework.Module.lib.fc_rbxsignals)
local AbilityObjects = Framework.Service.AbilityService.Ability.SmokeGrenade.Assets

local SmokeGrenade = {
    Options = {
        -- data
        name = "SmokeGrenade",
        inventorySlot = "secondary",
        isGrenade = true,
        
        -- general
        cooldownLength = 8, -- 10
        uses = 100,
        usingDelay = 1, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time

        -- grenade
        grenadeThrowDelay = 0.36,
        acceleration = 10,
        speed = 150,
        gravityModifier = 0.5,
        startHeight = 2,
        velocitySlowMultPerInterval = 0.7,
        velocitySlowIntervalSec = 0.1,
        velocityMinimum = 0.5,
        popLength = 1.5, -- 1.8

        -- animation / holding
        clientGrenadeSize = Vector3.new(0.328, 1.047, 0.359),
        grenadeVMOffsetCFrame = false, -- if you have a custom animation already, set this to false
        throwAnimFadeTime = 0.18,
        throwFinishSpringShove = Vector3.new(-0.4, -0.5, 0.2),

        -- smoke grenade specific
        smokeLength = 2.9, -- 4
        smokeFadeInLength = 0.4, -- 0.8
        smokeFadeOutLength = 0.8, -- 1
        smokeBubbleStartSizeModifier = 0.3,
        smokeBubbleStartTransparency = 0.7,

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
    }
}

function SmokeGrenade:FireGrenadePost(_, _, _, grenade)
    self.PopBindable = self.PopBindable or Instance.new("BindableEvent", script)
    game:GetService("CollectionService"):AddTag(grenade, "DestroyOnPlayerDied_" .. self.Player.Name)
    self.Grenade = grenade
    self:ConnectPop()
    task.delay(self.Options.popLength, function()
        self.PopBindable:Fire()
    end)
end

function SmokeGrenade:RayHit(_, result, velocity, grenade)
	local normal = result.Normal
	local reflected = velocity - 2 * velocity:Dot(normal) * normal
    grenade.CanCollide = true
    grenade.CollisionGroup = "Grenades"
    grenade.Velocity = reflected * 0.3
    Sound.Sounds("PlayClone", AbilityObjects.Sounds.Hit:GetChildren(), grenade)
    self:ConnectGrenadeHit(grenade)
    return
end

function SmokeGrenade:Pop(position)
    SmokeGrenade.CreateSmokeBubble(position)
end

local function setvel(grenade, touched)
    local newMagnitude = grenade.Velocity.Magnitude * (touched and 0.8 or SmokeGrenade.Options.velocitySlowMultPerInterval)

    if newMagnitude < SmokeGrenade.Options.velocityMinimum then
        grenade.Anchored = true
        return
    end

    grenade.Velocity = grenade.Velocity.Unit * newMagnitude
end

function SmokeGrenade:ConnectPop()
    self.PopBindable.Event:Once(function()
        self:DisconnectGrenade()
        self:Pop(self.Grenade.CFrame.Position)
        self.Grenade:Destroy()
    end)
end

function SmokeGrenade:ConnectGrenadeHit(grenade)
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

function SmokeGrenade:ConnectGrenadeSlow(grenade)
    local _time = 0
    self.Connections = ConnectionsLib.TableConnect(self.Connections, "SlowTime", RunService.Heartbeat:Connect(function(dt)
        _time += dt
        if _time >= SmokeGrenade.Options.velocitySlowIntervalSec then
            _time -= SmokeGrenade.Options.velocitySlowIntervalSec
            setvel(grenade)
        end
    end))
end

function SmokeGrenade:DisconnectGrenade()
    ConnectionsLib.DisconnectAllIn(self.Connections)
end

function SmokeGrenade.CreateSmokeBubble(pos)
    local bubble = AbilityObjects.Models.SmokeBubble:Clone()
    local bubbleSize = bubble.Size
    bubble.Size *= SmokeGrenade.Options.smokeBubbleStartSizeModifier
    bubble.Anchored = true
    bubble.CanCollide = false
    bubble.CollisionGroup = "BulletAndMovementIgnore"
    bubble:SetAttribute("SmokeLength", SmokeGrenade.Options.smokeLength)
    bubble:SetAttribute("SmokeFadeInLength", SmokeGrenade.Options.smokeFadeInLength)
    bubble:SetAttribute("SmokeFadeOutLength", SmokeGrenade.Options.smokeFadeOutLength)
    bubble.Parent = workspace.Temp
    bubble.CFrame = CFrame.new(pos)

    Sound.PlayClone(AbilityObjects.Sounds.Pop, bubble)

    TweenService:Create(bubble, TweenInfo.new(SmokeGrenade.Options.smokeFadeInLength), {Size = bubbleSize, Transparency = 0}):Play()
    local out = TweenService:Create(bubble, TweenInfo.new(SmokeGrenade.Options.smokeFadeOutLength), {Size = bubbleSize * SmokeGrenade.Options.smokeBubbleStartSizeModifier, Transparency = 1})
    task.delay(SmokeGrenade.Options.smokeLength, function()
        pcall(function() bubble.ParticleEmitter.Enabled = false bubble.SmokeT.Enabled = false bubble.SmokeB.Enabled = false end)
        out:Play()
        out.Completed:Wait()
        Debris:AddItem(bubble, 3)
    end)
end

function SmokeGrenade.ServerPop(position)
    SmokeGrenade.CreateSmokeBubble(position)
end

return SmokeGrenade