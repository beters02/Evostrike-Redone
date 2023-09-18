local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AbilityObjects = ReplicatedStorage:WaitForChild("ability"):WaitForChild("obj"):WaitForChild("Molly")
local Sound = require(Framework.shm_sound.Location)
local EvoPlayer = require(ReplicatedStorage.Modules.EvoPlayer)
local AbilityReplicateRF: RemoteFunction = ReplicatedStorage.ability.remote.replicate
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Molly = {
    name = "Molly",
    isGrenade = true,
    
    -- general settings
    cooldownLength = 10,
    uses = 100,
    usingDelay = 1, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time

    -- useage
    grenadeThrowDelay = 0.36,

    -- grenade
    acceleration = 10,
    speed = 150,
    gravityModifier = 0.5,
    startHeight = 2,

    -- animation / holding
    clientGrenadeSize = Vector3.new(0.328, 1.047, 0.359),
    grenadeVMOffsetCFrame = false, -- if you have a custom animation already, set this to false
    throwAnimFadeTime = 0.18,
    throwFinishSpringShove = Vector3.new(-0.4, -0.5, 0.2),

    -- molotov settings
    mollyLength = 4,
    mollyFadeLength = 1,
    damageInterval = 0.4,
    damagePerInterval = 15,

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
    },

    -- data settings
    abilityName = "Molly",
    inventorySlot = "secondary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
    remoteEvent = nil,
}

function Molly.GetParams()
    local op = OverlapParams.new()
    op.CollisionGroup = "MollyDamageCast"
    return op
end

function Molly.CreateCirclePart(position)
    local vispart = AbilityObjects.Models.MollyPreset:Clone()
    vispart.Size = Vector3.new(0.1, 15, 15)
    vispart.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.pi*-.5)
    vispart.CollisionGroup = "Bullets"
    vispart.Attachment.Glow.Size = NumberSequence.new(vispart.Size.Z)
    vispart.Attachment.Rays.Size = NumberSequence.new(math.min(1, vispart.Size.Z/2))
    vispart.Attachment.Fire.Size = NumberSequence.new(vispart.Size.Z * 0.4)
    vispart.Transparency = 0.7
    vispart.Parent = workspace.Temp

    local hitpart = vispart:Clone()
    hitpart.Size = Vector3.new(10, hitpart.Size.Y, hitpart.Size.Z)
    hitpart.Parent = workspace.Temp
    hitpart.Transparency = 1

    local anim = {}
    anim.stop = false
    anim.loop = task.spawn(function()
        local _t
        while vispart and not anim.stop do
            if not vispart or anim.stop then break end
            if _t then _t:Destroy() end
            vispart.Transparency = 0.7
            _t = TweenService:Create(vispart, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Transparency = 1})
            _t:Play()

            repeat task.wait() until not vispart or anim.stop or _t.PlaybackState == Enum.PlaybackState.Cancelled or _t.PlaybackState == Enum.PlaybackState.Completed
            if not vispart or anim.stop then break end
            _t:Destroy()
            
            vispart.Transparency = 1
            _t = TweenService:Create(vispart, TweenInfo.new(0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Transparency = 0.7})
            _t:Play()

            repeat task.wait() until not vispart or anim.stop or _t.PlaybackState == Enum.PlaybackState.Cancelled or _t.PlaybackState == Enum.PlaybackState.Completed
            if not vispart or anim.stop then break end
        end
    end)
    anim.Stop = function(self)
        anim.stop = true
    end

    return vispart, hitpart, anim
end

function Molly.RayHit(grenadeClassObject, casterPlayer, caster, result, velocity, behavior, playerLookNormal)
    local grenade = grenadeClassObject.CurrentGrenadeObject
    local explode = true
    local touchedConn

    print(grenadeClassObject)
    print(casterPlayer)

    local position = result.Position
	local normal = result.Normal
	local reflected = velocity - 2 * velocity:Dot(normal) * normal

    -- Bounce if Grenade has not landed on flat ground
    if result.Normal ~= Vector3.new(0,1,0) then
        explode = false
        grenade.CanCollide = true
        grenade.Velocity = reflected * 0.3

        -- listen for bouncing
        touchedConn = grenade.Touched:Connect(function(part)

            -- play hit sound
            Sound.PlayClone(AbilityObjects.Sounds.GlassImpact, grenade, {TimePosition = 0.3})
            Sound.PlayClone(AbilityObjects.Sounds.GlassHit, grenade)

            -- ground casting
            local p = RaycastParams.new()
            p.FilterDescendantsInstances = {grenade}
            p.FilterType = Enum.RaycastFilterType.Exclude
            local g = workspace:Raycast(grenade.Position, Vector3.new(0,-1,0) * 2, p)
            if not g then return end

            position = g.Position
            explode = true
            touchedConn:Disconnect()
        end)
    end

    -- Wait for explosion to be ready, then handle the Grenade Model cleanup
    if not explode then repeat task.wait() until explode end

    grenade.Anchored = true
    grenade.Transparency = 1
    Debris:AddItem(grenade, 3)

    -- Send remote server request to handle explosion
    if casterPlayer == Players.LocalPlayer then
        AbilityReplicateRF:FireServer("MollyServerExplode", position)
    end

    return
end

function Molly.ServerExplode(position)
    if RunService:IsClient() then return end

    -- create circle radius
    local circlepart, hitpart, animTable = Molly.CreateCirclePart(position)

    -- play pop sounds
    Sound.PlayClone(AbilityObjects.Sounds.Pop, circlepart)
    Sound.PlayClone(AbilityObjects.Sounds.InitialFire, circlepart)
    Sound.PlayClone(AbilityObjects.Sounds.Fire, circlepart)

    local t = tick() + Molly.mollyLength
    local conn
    local charsDamaging = {}
    local charsRegisteredDamagingThisCycle = {}

    conn = RunService.Heartbeat:Connect(function()

        if not circlepart or not hitpart or tick() >= t then
            for i, v in pairs(charsDamaging) do
                v.connection:Disconnect()
            end

            -- clean up function
            Molly.ServerCleanUpParts(circlepart, hitpart, animTable)

            conn:Disconnect()
            return
        end

        local resultArray = workspace:GetPartsInPart(hitpart, Molly.GetParams())
        if #resultArray > 1 then
            for i, v in pairs(resultArray) do
                local char = v.Parent
                if not charsDamaging[char.Name] then
                    charsDamaging[char.Name] = {nextDamageTick = tick(), connection = RunService.Heartbeat:Connect(function()
                        if tick() >= charsDamaging[char.Name].nextDamageTick then
                            if not char:FindFirstChild("Humanoid") then return end
                            charsDamaging[char.Name].nextDamageTick = Molly.damageInterval + tick()
                            char:SetAttribute("lastHitPart", "LeftFoot")
                            char:SetAttribute("lastUsedWeapon", "Ability")
                            EvoPlayer:TakeDamage(char, Molly.damagePerInterval)
                        end
                    end)}
                end

                if not charsRegisteredDamagingThisCycle[char.Name] then charsRegisteredDamagingThisCycle[char.Name] = true end
            end
        end

        -- remove any players that are not currently being damaged
        for i, v in pairs(charsDamaging) do
            if not charsRegisteredDamagingThisCycle[i] then
                v.connection:Disconnect()
                charsDamaging[i] = nil
            end
        end

        charsRegisteredDamagingThisCycle = {}
    end)

end

function Molly.ServerCleanUpParts(visualizerPart, damagerPart, animTable)
    if animTable then animTable:Stop() end
    if damagerPart then damagerPart:Destroy() end
    
    if visualizerPart then -- fade molly out
        if not visualizerPart:GetAttribute("IsDestroying") then
            visualizerPart:SetAttribute("IsDestroying", true)

            -- sounds
            task.spawn(function()
                for i, v in pairs(visualizerPart:GetChildren()) do
                    if v:IsA("Sound") then
                        TweenService:Create(v, TweenInfo.new(Molly.mollyFadeLength), {Volume = 0})
                    end
                end
            end)

            task.delay(0.1, function()
                TweenService:Create(visualizerPart, TweenInfo.new(Molly.mollyFadeLength), {Transparency = 1}):Play()
            end)

            if visualizerPart:FindFirstChild("Attachment") then
                for i, v in pairs(visualizerPart.Attachment:GetChildren()) do
                    TweenService:Create(v, TweenInfo.new(Molly.mollyFadeLength), {Rate = 0}):Play()
                end
            end

            task.wait(Molly.mollyFadeLength + 2)

            visualizerPart:Destroy()
            damagerPart:Destroy()
        end
    end
end

return Molly