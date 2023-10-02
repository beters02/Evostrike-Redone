local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AbilityObjects = Framework.Service.AbilityService.Ability.LongFlash.Assets
local Sound = require(Framework.Module.Sound)
local States = require(Framework.Module.m_states)
local Math = require(Framework.Module.lib.fc_math)
local FastCast = require(ReplicatedStorage.lib.c_fastcast)
local Replicate = ReplicatedStorage.Services.AbilityService.Events.Replicate

local PlayerActionsState

local BotService
if RunService:IsServer() then 
    BotService = require(ReplicatedStorage:WaitForChild("Services"):WaitForChild("BotService")) 
else
    PlayerActionsState = States.State("PlayerActions")
end

local LongFlash = {
    Configuration = {

        -- data
        name = "LongFlash",
        isGrenade = true,
        inventorySlot = "secondary",

        -- general
        cooldownLength = 7,
        uses = 100,
        usingDelay = 1, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time

        -- grenade
        grenadeThrowDelay = 0.2,
        acceleration = 16,
        speed = 150,
        gravityModifier = 0.4,
        startHeight = 2,

        -- animation / holding
        clientGrenadeSize = nil,
        grenadeVMOffsetCFrame = CFrame.Angles(0,math.rad(80),0) + Vector3.new(0, 0, 0.4), -- if you have a custom animation already, set this to nil
        throwAnimFadeTime = 0.18,
        throwFinishSpringShove = Vector3.new(-0.4, -0.5, 0.2),

        -- flash specific
        anchorTime = 0.2,
        anchorDistance = 5,
        popTime = 0.3,
        blindLength = 1.5,
        canSeeAngle = 1.07,
        flashGui = AbilityObjects:WaitForChild("FlashbangGui"),
        flashEmitter = AbilityObjects:WaitForChild("Emitter"),

        -- absr = Absolute Value Random
        -- rtabsr = Random to Absolute Value Random
        useCameraRecoil = {
            downDelay = 0.07,

            up = 0.02,
            side = 0.008,
            shake = "0.015-0.035rtabsr",

            speed = 4,
            force = 60,
            damp = 4,
            mass = 9
        }
    },

    -- Module Scope Storage
    flashGui = AbilityObjects:WaitForChild("FlashbangGui"),
    flashEmitter = AbilityObjects:WaitForChild("Emitter")
}

-- Create Caster
local caster
local castBehavior
local function initCaster()
	caster = FastCast.new()
	castBehavior = FastCast.newBehavior()
	castBehavior.Acceleration = Vector3.new(0, -workspace.Gravity * LongFlash.Configuration.gravityModifier, 0)
	castBehavior.AutoIgnoreContainer = false
	castBehavior.CosmeticBulletContainer = workspace.Temp
	castBehavior.CosmeticBulletTemplate = AbilityObjects.Models.Grenade
    LongFlash.caster = caster
    LongFlash.castBehavior = castBehavior
    LongFlash.caster.RayHit:Connect(function(...)
        LongFlash.RayHit(caster, Players.LocalPlayer, ...)
    end)
    LongFlash.caster.LengthChanged:Connect(function(_, lastPoint, direction, length, _, bullet) -- cast, lastPoint, direction, length, velocity, bullet
        if bullet then
            local bulletLength = bullet.Size.Z/2
            local offset = CFrame.new(0, 0, -(length - bulletLength))
            bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
        end
    end)
    LongFlash.caster.CastTerminating:Connect(function() if LongFlash.currentGrenadeObject then Debris:AddItem(LongFlash.currentGrenadeObject, 3) end end)
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

-- LongFlash Utility

--@summary
local function disableAllParticleEmittersAndLights(grenadeModel)
    for i, v in pairs(grenadeModel:GetChildren()) do
        if v:IsA("ParticleEmitter") then
            v.Rate = 0
        elseif v:IsA("PointLight") then
           local _t = TweenService:Create(v, TweenInfo.new(0.2, Enum.EasingStyle.Cubic), {Brightness = 0, Range = 0})
           _t:Play()
           _t.Completed:Once(function()
                _t:Destroy()
           end)
        elseif v:IsA("Attachment") then
            disableAllParticleEmittersAndLights(v)
        end
    end
end

-- End LongFlash Utility

--@override
--@summary Grenade Ability UseCore Override
function LongFlash:UseCore()
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
function LongFlash:Use()

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

    -- long flash does CanUse on the server via remoteFunction: ThrowGrenade
    local hit = self.Player:GetMouse().Hit

    -- grenade usage
    self:FireGrenade(hit)

    -- destroy left hand clone
    grenadeClone:Destroy()
    m6:Destroy()
end

--@summary Required Grenade Function FireGrenade
function LongFlash:FireGrenade(hit, isReplicated, origin, direction, thrower)
    if not isReplicated then
        local startLv = Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
        origin = Players.LocalPlayer.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, self.Options.startHeight, 0)
        direction = (hit.Position - origin).Unit
        Replicate:FireServer("GrenadeFire", self.Options.name, origin, direction)
    end

    local castParams = thrower and getOtherParams(thrower) or getLocalParams()
    self.castBehavior.RaycastParams = castParams

    local cast = self.caster:Fire(origin, direction, self.Options.speed, self.castBehavior)
    LongFlash.currentGrenadeObject = cast.RayInfo.CosmeticBulletObject
end

--@summary Required Grenade Function RayHit
-- grenadeClassObject, casterPlayer, caster, result, velocity, behavior, playerLookNormal
function LongFlash.RayHit(_, _, _, result)

    local grenadeModel = LongFlash.currentGrenadeObject

    -- send grenade outward
    local outDirection = result.Normal * LongFlash.Configuration.anchorDistance
    local newPos = grenadeModel.Position + outDirection

    -- cehck for collision
    local outResult = workspace:Raycast(grenadeModel.Position, outDirection)
    if outResult then
        newPos = outResult.Position
    end

    -- set emitter variables
    for _, v in pairs(grenadeModel:GetChildren()) do
        if not v:IsA("ParticleEmitter") or not v.Name == "Spark" then continue end
        v = v :: ParticleEmitter
        v.Speed = NumberRange.new(10, 20)
        v.Lifetime = NumberRange.new(0.1, 0.1)
        v.Rate = 30
    end

    -- init pop animation & position tweens
    local tModelSize = TweenService:Create(grenadeModel, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true), {Size = grenadeModel.Size * 10})
    local tPointLight = TweenService:Create(grenadeModel.PointLight, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true), {Range = 60})
    local tPosition = TweenService:Create(grenadeModel, TweenInfo.new(LongFlash.Configuration.anchorTime), {Position = newPos})

    -- play anchor and hit sound
    Sound.PlayClone(AbilityObjects.Sounds.Anchor, grenadeModel)
    Sound.PlayClone(AbilityObjects.Sounds.Hit, grenadeModel)
    
    -- send grenade out reflected
    tPosition:Play()
    tPosition.Completed:Wait()

    -- once the grenade has reached its reflection time (anchor time), wait another small amount of times so players can react.
    -- we'll send the server info here too, optiiiiii
    task.delay(LongFlash.Configuration.popTime, function()
        Replicate:FireServer("LongFlashServerPop", newPos, LongFlash.CanSee(grenadeModel))
    end)

    grenadeModel.Anchored = true
    task.wait(LongFlash.Configuration.popTime)

    -- play pop sound
    Sound.PlayClone(AbilityObjects.Sounds.Pop, grenadeModel)

    tModelSize:Play()
    tPointLight:Play()
    tPointLight.Completed:Wait()

    -- set emitter variables
    for i, v in pairs(grenadeModel:GetChildren()) do
        if not v:IsA("ParticleEmitter") or not v.Name == "Spark" then continue end
        v = v :: ParticleEmitter
        v.Speed = NumberRange.new(40, 60)
        v.Lifetime = NumberRange.new(0.1, 0.1)
        v.Rate = 60
    end

    grenadeModel.Transparency = 1
    disableAllParticleEmittersAndLights(grenadeModel)
    Debris:AddItem(grenadeModel, 2)
end

--@summary Required Grenade Function PlayEquipCameraRecoil
function LongFlash:PlayEquipCameraRecoil()
    self.Variables.cameraLastEquipShove = Vector3.new(0.01, Math.absr(0.01), 0)
    self.Variables.cameraSpring:shove(self.Variables.cameraLastEquipShove)
    task.wait()
    self.Variables.cameraSpring:shove(-self.Variables.cameraLastEquipShove)
end

-- [[ LongFlash Specific Functions ]]

--@summary Blind BotPlayers
function LongFlash.BlindBots(pos)
    for _, v in pairs(BotService:GetBots()) do
        task.spawn(function()
            LongFlash.AttemptBlindPlayer(v, pos, true)
        end)
    end
end

--@summary Blind a player if they are blindable
function LongFlash.AttemptBlindPlayer(player, pos, isBot)

    -- check if flash can hit player (wall collision)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {workspace.Temp, workspace.MovementIgnore}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.CollisionGroup = "FlashCast"

    local result = workspace:Raycast(pos, ((player.Character:WaitForChild("Head").CFrame.Position - Vector3.new(0,0,0)) - pos).Unit * 250, params)
    print(result)
    local resultModel = result and result.Instance:FindFirstAncestorWhichIsA("Model")
    if (resultModel and resultModel ~= player.Character) or not string.match(result.Instance.Name, "Head") then
        return
    end

    -- create emitter
    local c = LongFlash.flashEmitter:Clone()
    c.Parent = player.Character.Head
    c.Enabled = true

     -- gui responsible for "blinding" the player
    if not isBot then
        local gui = LongFlash.flashGui:Clone()
        gui.FlashedFrame.Transparency = 1
        gui.Parent = player.PlayerGui

        -- create and play player blinded tweens
        local fadeInTween = TweenService:Create(gui.FlashedFrame, TweenInfo.new(0.3), {Transparency = 0})
        fadeInTween:Play()

        local fadeOutTween = TweenService:Create(gui.FlashedFrame, TweenInfo.new(0.2), {Transparency = 1})
        local cFadeTween = TweenService:Create(c, TweenInfo.new(0.25), {Rate = 0})
        
        -- fade out tweens
        task.delay(LongFlash.Configuration.blindLength, function() 
            fadeOutTween:Play()
            cFadeTween:Play()
            task.spawn(function()
                cFadeTween.Completed:Wait()
                cFadeTween:Destroy()
            end)
            Debris:AddItem(gui, 0.5) -- destroy gui
            Debris:AddItem(c, 0.5)
        end)

    else

        local cFadeTween = TweenService:Create(c, TweenInfo.new(0.25), {Rate = 0})
        task.delay(LongFlash.Configuration.blindLength, function()
            cFadeTween:Play()
            task.spawn(function()
                cFadeTween.Completed:Wait()
                cFadeTween:Destroy()
                Debris:AddItem(c, 0.5)
            end)
        end)

    end
end

--@summary Check if the LocalPlayer can see part
function LongFlash.CanSee(part)
    local pos = part.Position
    local vector, inViewport = workspace.CurrentCamera:WorldToViewportPoint(pos)
    local onScreen = inViewport and vector.Z > 0
    if onScreen then
        return true
    end
    return false
end

return LongFlash