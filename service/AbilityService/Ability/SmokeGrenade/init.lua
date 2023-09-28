local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.shared.sound.m_sound)
local EvoPlayer = require(ReplicatedStorage.Modules.EvoPlayer)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local FastCast = require(ReplicatedStorage.lib.c_fastcast)
local Replicate = ReplicatedStorage.Services.AbilityService.Events.Replicate
local States = require(Framework.Module.shared.states.m_states)
local AbilityObjects = Framework.Service.AbilityService.Ability.SmokeGrenade.Assets
local Math = require(Framework.Module.lib.fc_math)

local PlayerActionsState
if RunService:IsClient() then PlayerActionsState = States.State("PlayerActions") end


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
        smokeLength = 7,
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
    }
}

-- Create Caster
local caster
local castBehavior
local function initCaster()
	caster = FastCast.new()
	castBehavior = FastCast.newBehavior()
	castBehavior.Acceleration = Vector3.new(0, -workspace.Gravity * SmokeGrenade.Configuration.gravityModifier, 0)
	castBehavior.AutoIgnoreContainer = false
	castBehavior.CosmeticBulletContainer = workspace.Temp
	castBehavior.CosmeticBulletTemplate = AbilityObjects.Models.Grenade
    SmokeGrenade.caster = caster
    SmokeGrenade.castBehavior = castBehavior
    SmokeGrenade.caster.RayHit:Connect(function(...)
        SmokeGrenade.RayHit(caster, Players.LocalPlayer, ...)
    end)
    SmokeGrenade.caster.LengthChanged:Connect(function(_, lastPoint, direction, length, _, bullet) -- cast, lastPoint, direction, length, velocity, bullet
        if bullet then
            local bulletLength = bullet.Size.Z/2
            local offset = CFrame.new(0, 0, -(length - bulletLength))
            bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
        end
    end)
    SmokeGrenade.caster.CastTerminating:Connect(function()end)
    if RunService:IsClient() then
        SmokeGrenade.popbindable = Instance.new("BindableEvent", AbilityObjects.Parent)
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
function SmokeGrenade:UseCore()
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
function SmokeGrenade:Use()

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
function SmokeGrenade:FireGrenade(hit, isReplicated, origin, direction, thrower)
    if not isReplicated then
        local startLv = Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
        origin = Players.LocalPlayer.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, self.Options.startHeight, 0)
        direction = (hit.Position - origin).Unit
        Replicate:FireServer("GrenadeFire", self.Options.name, origin, direction)
    end

    local castParams = thrower and getOtherParams(thrower) or getLocalParams()
    self.castBehavior.RaycastParams = castParams

    local cast = self.caster:Fire(origin, direction, self.Options.speed, self.castBehavior)
    SmokeGrenade.currentGrenadeObject = cast.RayInfo.CosmeticBulletObject

    task.delay(self.Options.smokeLengthBeforePop, function()
        if SmokeGrenade.touchedConn then
            SmokeGrenade.touchedConn:Disconnect()
            SmokeGrenade.touchedConn = nil
        end
        if SmokeGrenade.slowTimeConn then
            SmokeGrenade.slowTimeConn:Disconnect()
            SmokeGrenade.slowTimeConn = nil
        end
        Debris:AddItem(SmokeGrenade.currentGrenadeObject, 3)
        SmokeGrenade.currentGrenadeObject.Transparency = 1
        if not thrower then
            -- only fire this event if there is not a thrower variable, which means that the thrower is the LocalPlayer
            SmokeGrenade.popbindable:Fire()
        end
    end)
end

--@summary Required Grenade Function RayHit
-- grenadeClassObject, casterPlayer, caster, result, velocity, behavior, playerLookNormal)
function SmokeGrenade.RayHit(_, casterPlayer, _, result, velocity)

    local grenade = SmokeGrenade.currentGrenadeObject
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

    if casterPlayer == Players.LocalPlayer then
        -- Send remote server request once popbindable has fired
        SmokeGrenade.popbindable.Event:Wait()
        Replicate:FireServer("SmokeGrenadeServerPop", grenade.Position)
    end

    return
end

--@summary Required Grenade Function PlayEquipCameraRecoil
function SmokeGrenade:PlayEquipCameraRecoil()
    self.Variables.cameraLastEquipShove = Vector3.new(0.01, Math.absr(0.01), 0)
    self.Variables.cameraSpring:shove(self.Variables.cameraLastEquipShove)
    task.wait()
    self.Variables.cameraSpring:shove(-self.Variables.cameraLastEquipShove)
end

-- [[ SMOKE GRENADE SPECIFIC FUNCTIONS ]]

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

--@summary Clean up the Molly's Fire Visuals
--[[function Molly.ServerCleanUpParts(visualizerPart, damagerPart, animTable)
    if animTable then animTable:Stop() end
    if damagerPart then damagerPart:Destroy() end
    
    if visualizerPart then -- fade molly out
        if not visualizerPart:GetAttribute("IsDestroying") then
            visualizerPart:SetAttribute("IsDestroying", true)

            -- sounds
            task.spawn(function()
                for _, v in pairs(visualizerPart:GetChildren()) do
                    if v:IsA("Sound") then
                        TweenService:Create(v, TweenInfo.new(Molly.Configuration.mollyFadeLength), {Volume = 0})
                    end
                end
            end)

            task.delay(0.1, function()
                TweenService:Create(visualizerPart, TweenInfo.new(Molly.Configuration.mollyFadeLength), {Transparency = 1}):Play()
            end)

            if visualizerPart:FindFirstChild("Attachment") then
                for _, v in pairs(visualizerPart.Attachment:GetChildren()) do
                    TweenService:Create(v, TweenInfo.new(Molly.Configuration.mollyFadeLength), {Rate = 0}):Play()
                end
            end

            task.wait(Molly.Configuration.mollyFadeLength + 2)

            visualizerPart:Destroy()
            damagerPart:Destroy()
        end
    end
end]]

return SmokeGrenade