local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local Players = game:GetService("Players")
local FastCast = require(ReplicatedStorage.lib.c_fastcast)
local Replicate = ReplicatedStorage.Services.AbilityService.Events.Replicate
local States = require(Framework.Module.m_states)
local AbilityObjects = Framework.Service.AbilityService.Ability.HEGrenade.Assets
local Math = require(Framework.Module.lib.fc_math)
local EvoPlayer = require(Framework.Module.shared.Modules.EvoPlayer)

local PlayerActionsState
if RunService:IsClient() then PlayerActionsState = States.State("PlayerActions") end


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
        velocitySlowMultPerInterval = 0.7,
        velocitySlowIntervalSec = 0.1,
        velocityMinimum = 0.5,

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

-- Create Caster
local caster
local castBehavior
local function initCaster()
	caster = FastCast.new()
	castBehavior = FastCast.newBehavior()
	castBehavior.Acceleration = Vector3.new(0, -workspace.Gravity * HEGrenade.Configuration.gravityModifier, 0)
	castBehavior.AutoIgnoreContainer = false
	castBehavior.CosmeticBulletContainer = workspace.Temp
	castBehavior.CosmeticBulletTemplate = AbilityObjects.Models.Grenade
    HEGrenade.caster = caster
    HEGrenade.castBehavior = castBehavior
    HEGrenade.caster.RayHit:Connect(function(...)
        HEGrenade.RayHit(caster, Players.LocalPlayer, ...)
    end)
    HEGrenade.caster.LengthChanged:Connect(function(_, lastPoint, direction, length, _, bullet) -- cast, lastPoint, direction, length, velocity, bullet
        if bullet then
            local bulletLength = bullet.Size.Z/2
            local offset = CFrame.new(0, 0, -(length - bulletLength))
            bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
        end
    end)
    HEGrenade.caster.CastTerminating:Connect(function()end)
    if RunService:IsClient() then
        HEGrenade.popbindable = Instance.new("BindableEvent", AbilityObjects.Parent)
    end
end
initCaster()

local function getLocalParams()
    local locparams = RaycastParams.new()
    locparams.CollisionGroup = "Grenades"
    locparams.FilterType = Enum.RaycastFilterType.Exclude
    locparams.FilterDescendantsInstances = {workspace.CurrentCamera, Players.LocalPlayer.Character}
    return locparams
end

local function getOtherParams(thrower)
    local otherCastParams = RaycastParams.new()
    otherCastParams.CollisionGroup = "Grenades"
    otherCastParams.FilterType = Enum.RaycastFilterType.Exclude
    otherCastParams.FilterDescendantsInstances = {thrower.Character}
    return otherCastParams
end

--

--@override
--@summary Grenade Ability UseCore Override
function HEGrenade:UseCore()
    if self.Variables.Uses <= 0 or self.Variables.OnCooldown then
        return
    end
    self.Variables.Uses -= 1
    self:Cooldown()

    task.delay(self.Options.grenadeThrowDelay, function()
        self:UseCameraRecoil()
    end)
    self:PlayEquipCameraRecoil()

    self:Use()
end

--@summary Required Ability Function Use
function HEGrenade:Use()

    PlayerActionsState:set("grenadeThrowing", true)
    task.delay(self.Variables.usingDelay, function()
        PlayerActionsState:set("grenadeThrowing", false)
    end)

    Sound.PlayReplicatedClone(AbilityObjects.Sounds.Equip, self.Player.Character.PrimaryPart)
    self:PlayEquipCameraRecoil()

    -- make player hold grenade in left hand
    workspace.CurrentCamera.viewModel.LeftEquipped:ClearAllChildren()

    local grenadeClone = AbilityObjects.Models.Grenade:Clone()
    grenadeClone.Parent = workspace.CurrentCamera.viewModel.LeftEquipped
    if self.Options.clientGrenadeSize then
        grenadeClone.Size = self.Options.clientGrenadeSize
    else
        grenadeClone.Size *= 0.8
    end

    local leftHand = self.Viewmodel.LeftHand
    local m6 = leftHand:FindFirstChild("LeftGrip")
    if m6 then m6:Destroy() end
    m6 = Instance.new("Motor6D", leftHand)
    m6.Name = "LeftGrip"
    m6.Part0 = leftHand
    m6.Part1 = grenadeClone
    if self.Options.grenadeVMOffsetCFrame then m6.C0 = self.Options.grenadeVMOffsetCFrame end

    -- play throw animation
    self.Animations.throw:Play(self.Options.throwAnimFadeTime or 0.18)
    self.Animations.serverthrow:Play(self.Options.throwAnimFadeTime or 0.18)

    -- equip finish
    task.delay(self.Animations.throw.Length + ((self.Options.throwAnimFadeTime or 0.18)*1.45), function()
        if self.Variables._equipFinishCustomSpring then
            self.Variables._equipFinishCustomSpring.Shove()
        end
    end)

    task.wait(self.Options.grenadeThrowDelay or 0.01)

    -- play throw sound
    Sound.PlayReplicatedClone(AbilityObjects.Sounds.Throw, self.Player.Character.PrimaryPart)

    -- grenade usage
    self:FireGrenade(self.Player:GetMouse().Hit)

    -- destroy left hand clone
    grenadeClone:Destroy()
    m6:Destroy()
end

--@summary Required Grenade Function FireGrenade
function HEGrenade:FireGrenade(hit, isReplicated, origin, direction, thrower)
    if not isReplicated then
        local startLv = Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
        origin = Players.LocalPlayer.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, self.Options.startHeight, 0)
        direction = (hit.Position - origin).Unit
        Replicate:FireServer("GrenadeFire", self.Options.name, origin, direction)
    end

    local castParams = thrower and getOtherParams(thrower) or getLocalParams()
    self.castBehavior.RaycastParams = castParams

    local cast = self.caster:Fire(origin, direction, self.Options.speed, self.castBehavior)
    HEGrenade.currentGrenadeObject = cast.RayInfo.CosmeticBulletObject
    HEGrenade.currentGrenadeObject:SetAttribute("IsOwner", not isReplicated)

    task.delay(self.Options.popLength, function()
        if HEGrenade.touchedConn then
            HEGrenade.touchedConn:Disconnect()
            HEGrenade.touchedConn = nil
        end
        if HEGrenade.slowTimeConn then
            HEGrenade.slowTimeConn:Disconnect()
            HEGrenade.slowTimeConn = nil
        end
        Debris:AddItem(HEGrenade.currentGrenadeObject, 3)
        HEGrenade.currentGrenadeObject.Transparency = 1
        if not thrower then
            -- only fire this event if there is not a thrower variable, which means that the thrower is the LocalPlayer
            HEGrenade.popbindable:Fire()
        end
    end)
end

--@summary Required Grenade Function RayHit
-- grenadeClassObject, casterPlayer, caster, result, velocity, behavior, playerLookNormal)
function HEGrenade.RayHit(_, casterPlayer, _, result, velocity)

    local grenade = HEGrenade.currentGrenadeObject
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
    HEGrenade.touchedConn = grenade.Touched:Connect(function()
        if isInitialTouch then
            isInitialTouch = false
            return
        end
        Sound.Sounds("PlayClone", AbilityObjects.Sounds.Hit:GetChildren(), grenade)
        setvel(true)
    end)

    local _time = 0
    HEGrenade.slowTimeConn = RunService.RenderStepped:Connect(function(dt)
        _time += dt
        if _time >= HEGrenade.Configuration.velocitySlowIntervalSec then
            _time -= HEGrenade.Configuration.velocitySlowIntervalSec
            setvel(false)
        end
    end)
    
    print(isOwner)
    if isOwner then
        -- Send remote server request once popbindable has fired
        HEGrenade.popbindable.Event:Once(function()
            Replicate:FireServer("HEGrenadeServerPop", grenade.Position)
        end)
    end

    return
end

--@summary Required Grenade Function PlayEquipCameraRecoil
function HEGrenade:PlayEquipCameraRecoil()
    self.Variables.cameraLastEquipShove = Vector3.new(0.01, Math.absr(0.01), 0)
    self.Variables.cameraSpring:shove(self.Variables.cameraLastEquipShove)
    task.wait()
    self.Variables.cameraSpring:shove(-self.Variables.cameraLastEquipShove)
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
end

return HEGrenade