local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Framework = require(ReplicatedStorage.Framework)
local AbilityObjects = Framework.Service.AbilityService.Ability.Satchel.Assets
local Caster = require(Framework.Service.AbilityService.Caster)
local Sound = require(Framework.Module.Sound)
local EvoPlayer = require(Framework.Module.shared.Modules.EvoPlayer)
local Replicate = ReplicatedStorage.Services.AbilityService.Events.Replicate
local Math = require(Framework.Module.lib.fc_math)

local Satchel = {
    Configuration = {
        -- data
        name = "Satchel",
        inventorySlot = "primary",
        isGrenade = true,
        
        -- genral
        cooldownLength = 6,
        uses = 100,
        usingDelay = 0.3, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time

        -- grenade
        grenadeThrowDelay = 0.1,
        acceleration = 10,
        speed = 150,
        gravityModifier = 0.5,
        startHeight = 2,

        -- animation / holding
        clientGrenadeSize = Vector3.new(0.328, 1.047, 0.359),
        grenadeVMOffsetCFrame = false, -- if you have a custom animation already, set this to false
        throwAnimFadeTime = 0.18,
        throwFinishSpringShove = Vector3.new(-0.4, -0.5, 0.2),

        -- satchel specific
        lengthBeforePop = 2.5,
        explosionMaxDamage = 30,
        explosionMinDamage = 5,
        explosionDamageMaxRadius = 7,
        explosionMovementMaxRadius = 22,
        explosionStrength = 90,
        explosionMovementVelMax = 50,
        explosionMovementVelMin = 10,

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

Caster.new(Satchel)

--@override
--@summary Required Grenade Function RayHit
-- class, casterPlayer, casterThrower, result, velocity, grenade
function Satchel.RayHit(_, _, _, result, _, grenade)
    if grenade then
        print("SATCHEL RAY HIT")
        print(result)
        print(result.Instance.Parent.Name .. " - parent")
        local norm = result.Normal
        grenade.Anchored = true
        grenade.CFrame = CFrame.new(result.Position) * (CFrame.Angles(math.rad(-90), 0, 0))
        grenade.CFrame = CFrame.new(grenade.CFrame.Position, grenade.CFrame.Position - norm)
        grenade:SetAttribute("Normal", -norm)
        Sound.PlayClone(AbilityObjects.Sounds.Hit, grenade)
    end
end

--@override
function Satchel:FireGrenadePost(_, _, _, _, thrower, grenade)
    if self.satchelConnection then self.satchelConnection:Disconnect() end
    --grenade:SetAttribute("IsPopped", false)

    local _t = tick() + self.Options.lengthBeforePop
    local blasted = false
    self.satchelConnection = RunService.RenderStepped:Connect(function()
        if not grenade or tick() >= _t or blasted then
            return
        end

        if UserInputService:IsKeyDown(Enum.KeyCode[self.Key]) and not blasted then
            blasted = true
            self:Blast(thrower, grenade)
        end
    end)

    task.delay(self.Options.lengthBeforePop, function()
        if grenade and not blasted then
            self:Blast(thrower, grenade)
        end
    end)
end

function Satchel:Blast(thrower, grenade)
    --grenade:SetAttribute("IsPopped", true)
    local velmax = self.Options.explosionMovementVelMax
    local velmin = self.Options.explosionMovementVelMin
    local radmax = self.Options.explosionMovementMaxRadius
    local strength = self.Options.explosionStrength
    local hrpPos = self.HumanoidRootPart.CFrame.Position
    local grenPos = grenade.CFrame.Position
    thrower = self.Player

    Replicate:FireServer("SatchelServerPop", grenade.Position)

    if thrower.Character then
        local result = workspace:Raycast(grenPos, (hrpPos - grenPos).Unit * radmax, self:GetSatchelParams(grenade))
        if not result then warn("No result!") return end

        if result.Instance:FindFirstAncestorOfClass("Model") == self.Character then
            local dir = (hrpPos - grenPos).Unit
            local vel = dir * ((radmax-result.Distance)/radmax) * strength

            -- set Y velocity to ignore a negative Y value
            if vel.Y < velmin then
                vel = Vector3.new(vel.X, velmin, vel.Z)
            end

            vel = Math.fv3clamp(vel, velmin, velmax) --[[* -dir]]
            self.Player.Character.MovementScript.Events.Satchel:Fire(vel)
        end
    end
    
    grenade:Destroy()
    if self.satchelConnection then
        self.satchelConnection:Disconnect()
    end
end

function Satchel:GetSatchelParams(grenade)
    local _p = RaycastParams.new()
    _p.FilterType = Enum.RaycastFilterType.Exclude
    _p.FilterDescendantsInstances = {grenade}
    _p.CollisionGroup = "FlashCast"
    return _p
end

--@summary Pop the Grenade on the Server
function Satchel.ServerPop(thrower, position)
    if RunService:IsClient() then return end

    local _explosion = AbilityObjects.Models.ExplosionPart:Clone()
    _explosion.Anchored = true
    _explosion.Parent = workspace
    _explosion.CFrame = CFrame.new(position)

    task.spawn(function()
        Sound.Sounds("PlayClone", AbilityObjects.Sounds.Explode:GetChildren(), _explosion)
    end)

    task.wait()

    for _, plr in pairs(Players:GetPlayers()) do
        if thrower == plr then continue end
        if not plr.Character or plr.Character.Humanoid.Health <= 0 then continue end
        local distance = (plr.Character.PrimaryPart.Position - position).Magnitude
        local radius = Satchel.Configuration.explosionDamageMaxRadius
        if distance <= radius then
            plr.Character:SetAttribute("lastHitPart", "Torso")
            EvoPlayer:TakeDamage(plr.Character, math.clamp(((radius - distance)/radius) * Satchel.Configuration.explosionMaxDamage, Satchel.Configuration.explosionMinDamage, Satchel.Configuration.explosionMaxDamage))
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
    

return Satchel