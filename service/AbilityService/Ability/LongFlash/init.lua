local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local AbilityServiceRF = Framework.Service.AbilityService.Events.RemoteFunction
local Assets = Framework.Service.AbilityService.Ability.LongFlash.Assets

local LongFlash = {
    Options = {
        -- data
        name = "LongFlash",
        isGrenade = true,
        inventorySlot = "secondary",

        -- general
        cooldownLength = 6,
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
        anchorDistance = 7,
        popTime = 0.18,
        blindLength = 1.01,
        canSeeAngle = 1.07,

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
    }
}

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

--@summary Required Grenade Function RayHit
function LongFlash:RayHit(caster, result, segmentVelocity, grenadeModel)
    Debris:AddItem(grenadeModel, LongFlash.Options.popTime + LongFlash.Options.anchorTime + 0.3)

    -- send grenade outward
    local outDirection = result.Normal * LongFlash.Options.anchorDistance
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
    local tPosition = TweenService:Create(grenadeModel, TweenInfo.new(LongFlash.Options.anchorTime), {Position = newPos})

    -- play anchor and hit sound
    Sound.PlayClone(self.Module.Assets.Sounds.Anchor, grenadeModel)
    Sound.PlayClone(self.Module.Assets.Sounds.Hit, grenadeModel)
    
    -- send grenade out reflected
    tPosition:Play()
    tPosition.Completed:Wait()

    grenadeModel.Anchored = true
    task.wait(LongFlash.Options.popTime)

    if self.FlashCast(Players.LocalPlayer, newPos) and LongFlash.CanSee(grenadeModel) then
        self:BlindPlayer(Players.LocalPlayer)
    end

    -- play pop sound
    self:PlaySound(self.Module.Assets.Sounds.Pop, grenadeModel)

    -- clear throwing sound
    if grenadeModel:FindFirstChild("Throwing") then
        TweenService:Create(grenadeModel.Throwing, TweenInfo.new(0.1), {Volume = 0}):Play()
        task.delay(0.11, function()
            pcall(function()grenadeModel.Throwing:Stop()end)
        end)
    end

    tModelSize:Play()
    tPointLight:Play()
    tPointLight.Completed:Wait()

    -- set emitter variables
    for _, v in ipairs(grenadeModel:GetChildren()) do
        if not v:IsA("ParticleEmitter") or not v.Name == "Spark" then continue end
        v = v :: ParticleEmitter
        v.Speed = NumberRange.new(40, 60)
        v.Lifetime = NumberRange.new(0.1, 0.1)
        v.Rate = 60
    end

    grenadeModel.Transparency = 1
    disableAllParticleEmittersAndLights(grenadeModel)
end

-- check if flash can hit player (wall collision)
function LongFlash.FlashCast(player, pos)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {workspace.Temp, workspace.MovementIgnore}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.CollisionGroup = "FlashCast"
    local result = workspace:Raycast(pos, ((player.Character:WaitForChild("Head").CFrame.Position - Vector3.new(0,0,0)) - pos).Unit * 250, params)
    local resultModel = result and result.Instance:FindFirstAncestorWhichIsA("Model")
    if not result or (resultModel and resultModel ~= player.Character) or not string.match(result.Instance.Name, "Head") then
        return false
    end
    return true
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

--@summary Blind a player if they are blindable
function LongFlash:BlindPlayer(player, isBot)
    -- create emitter
    local c = Assets.Emitter:Clone()
    c.Parent = player.Character.Head
    c.Enabled = true

     -- gui responsible for "blinding" the player
    if not isBot then
        local gui = Assets.FlashbangGui:Clone()
        gui.FlashedFrame.Transparency = 1
        gui.Parent = player.PlayerGui

        -- create and play player blinded tweens
        local fadeInTween = TweenService:Create(gui.FlashedFrame, TweenInfo.new(0.3), {Transparency = 0})
        fadeInTween:Play()

        local fadeOutTween = TweenService:Create(gui.FlashedFrame, TweenInfo.new(0.2), {Transparency = 1})
        local cFadeTween = TweenService:Create(c, TweenInfo.new(0.25), {Rate = 0})
        
        -- fade out tweens
        task.delay(LongFlash.Options.blindLength, function() 
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
        task.delay(LongFlash.Options.blindLength, function()
            cFadeTween:Play()
            task.spawn(function()
                cFadeTween.Completed:Wait()
                cFadeTween:Destroy()
                Debris:AddItem(c, 0.5)
            end)
        end)
    end
end

return LongFlash