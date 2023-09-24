local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AbilityObjects = ReplicatedStorage:WaitForChild("ability"):WaitForChild("obj"):WaitForChild("LongFlash")
local Tables = require(Framework.Module.lib.fc_tables)
local Sound = require(Framework.shm_sound.Location)
local FastCast = require(ReplicatedStorage.lib.c_fastcast)
local BotService
local AbilityReplicateRF: RemoteEvent = ReplicatedStorage.ability.remote.replicate
if RunService:IsServer() then
    BotService = require(ReplicatedStorage:WaitForChild("Services"):WaitForChild("BotService"))
end
local GrenadeRemotes = ReplicatedStorage.Modules.Grenades.Remotes

local LongFlash = {
    name = "LongFlash",
    isGrenade = true,

    -- general settings
    cooldownLength = 7,
    uses = 100,
    usingDelay = 1, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time

    -- useage
    grenadeThrowDelay = 0.2,

    -- grenade
    acceleration = 16,
    speed = 150,
    gravityModifier = 0.4,
    startHeight = 2,

    -- animation / holding
    clientGrenadeSize = nil,
    grenadeVMOffsetCFrame = CFrame.Angles(0,math.rad(80),0) + Vector3.new(0, 0, 0.4), -- if you have a custom animation already, set this to nil
    throwAnimFadeTime = 0.18,
    throwFinishSpringShove = Vector3.new(-0.4, -0.5, 0.2),

    -- flash settings
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
    },

    -- data settings
    abilityName = "LongFlash",
    inventorySlot = "secondary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
    remoteEvent = nil,
}

-- Test
if RunService:IsClient() then
    RunService.RenderStepped:Connect(function()
        task.wait(1)
        for i, v in pairs({"speed", "gravityModifier", "acceleration"}) do
            local r = ReplicatedStorage:GetAttribute("v")
            if r and LongFlash[v] ~= r then
                LongFlash[v] = r
            end
        end
    end)
end

-- Create Caster

local caster
local castBehavior
local localConn = {}

local function initCaster()
	caster = FastCast.new()
	castBehavior = FastCast.newBehavior()
	castBehavior.Acceleration = Vector3.new(0, -workspace.Gravity * LongFlash.gravityModifier, 0)
	castBehavior.AutoIgnoreContainer = false
	castBehavior.CosmeticBulletContainer = workspace.Temp
	castBehavior.CosmeticBulletTemplate = AbilityObjects.Models.Grenade
    LongFlash.caster = caster
    LongFlash.castBehavior = castBehavior
    localConn.rayhit = LongFlash.caster.RayHit:Connect(function(...)
        LongFlash.RayHit(caster, Players.LocalPlayer, ...)
    end)
    localConn.lengthchanged = LongFlash.caster.LengthChanged:Connect(function(cast, lastPoint, direction, length, velocity, bullet)
        if bullet then
            local bulletLength = bullet.Size.Z/2
            local offset = CFrame.new(0, 0, -(length - bulletLength))
            bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
        end
    end)
    localConn.terminating = LongFlash.caster.CastTerminating:Connect(function()end)
end

initCaster()

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

function LongFlash:FireGrenade(hit, isReplicated, origin, direction)
    self.uses -= 1 -- client uses
    --self.grenadeClassObject = self.grenadeClassObject :: GrenadeTypes.Grenade
    --self.grenadeClassObject.Fire(hit)

    if not isReplicated then
        local startLv = Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
        origin = Players.LocalPlayer.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, self.startHeight, 0)
        direction = (hit.Position - origin).Unit
        GrenadeRemotes.Replicate:FireServer("GrenadeFire", self.name, origin, direction)
    end

    local cast = self.caster:Fire(origin, direction, self.speed, self.castBehavior)
    LongFlash.currentGrenadeObject = cast.RayInfo.CosmeticBulletObject
end

function LongFlash.BlindBots(pos)
    for _, v in pairs(BotService:GetBots()) do
        task.spawn(function()
            LongFlash.AttemptBlindPlayer(v, pos, true)
        end)
    end
end

function LongFlash.AttemptBlindPlayer(player, pos, isBot)

    -- check if flash can hit player (wall collision)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {workspace.Temp, workspace.MovementIgnore}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.CollisionGroup = "Bullets"

    local result = workspace:Raycast(pos, ((player.Character:WaitForChild("Head").CFrame.Position - Vector3.new(0,0,0)) - pos).Unit * 250, params)
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
        task.delay(LongFlash.blindLength, function() 
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
        task.delay(LongFlash.blindLength, function()
            cFadeTween:Play()
            task.spawn(function()
                cFadeTween.Completed:Wait()
                cFadeTween:Destroy()
                Debris:AddItem(c, 0.5)
            end)
        end)

    end
end

--@client
function LongFlash.CanSee(part)
    local pos = part.Position
    local vector, inViewport = workspace.CurrentCamera:WorldToViewportPoint(pos)
    local onScreen = inViewport and vector.Z > 0
    if onScreen then
        return true
    end
    return false
end

function LongFlash.RayHit(grenadeClassObject, casterPlayer, caster, result, velocity, behavior, playerLookNormal)

    local grenadeModel = LongFlash.currentGrenadeObject

    -- send grenade outward
    local outDirection = result.Normal * LongFlash.anchorDistance
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
    local tPosition = TweenService:Create(grenadeModel, TweenInfo.new(LongFlash.anchorTime), {Position = newPos})

    -- play anchor and hit sound
    Sound.PlayClone(AbilityObjects.Sounds.Anchor, grenadeModel)
    Sound.PlayClone(AbilityObjects.Sounds.Hit, grenadeModel)
    
    -- send grenade out reflected
    tPosition:Play()
    tPosition.Completed:Wait()

    -- once the grenade has reached its reflection time (anchor time), wait another small amount of times so players can react.
    -- we'll send the server info here too, optiiiiii
    task.delay(LongFlash.popTime, function()
        AbilityReplicateRF:FireServer("LongFlashServerPop", newPos, LongFlash.CanSee(grenadeModel))
    end)

    grenadeModel.Anchored = true
    task.wait(LongFlash.popTime)

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
    
    -- only register flash popping if server
   --[[ if RunService:IsServer() then
        LongFlash.FlashPop(grenadeModel)
        task.wait()
        grenadeModel:Destroy()
    else]]
end

return LongFlash