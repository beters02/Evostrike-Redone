local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local EvoPlayer = require(ReplicatedStorage.Modules.EvoPlayer)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Replicate = ReplicatedStorage.Services.AbilityService.Events.Replicate
local AbilityObjects = Framework.Service.AbilityService.Ability.Molly.Assets
local Caster = require(Framework.Service.AbilityService.Caster)

local Molly = {
    Configuration = {
        -- data
        name = "Molly",
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

        -- molotov specific
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
        }
    },
    AbilityObjects = AbilityObjects
}

Caster.new(Molly)

--@summary The Core FireGrenade function ran before FireGrenade. Not recommended to override
function Molly:FireGrenadeCore(hit, isReplicated, origin, direction, thrower)
    if not isReplicated then
        local startLv = Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector

        -- cast initial ray to ensure grenade doesnt go through walls/floor
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {Players.LocalPlayer.Character, workspace.CurrentCamera}
        params.FilterType = Enum.RaycastFilterType.Exclude

        local mos = Players.LocalPlayer:GetMouse()
        local mray = workspace.CurrentCamera:ScreenPointToRay(mos.X, mos.Y)
        local initresult = workspace:Raycast(mray.Origin, mray.Direction * 7, params)
        if initresult then
            self.currentGrenadeObject = AbilityObjects.Models.Grenade:Clone()
            self.currentGrenadeObject.CollisionGroup = "Default"
            self.currentGrenadeObject.CanCollide = true
            self.currentGrenadeObject.Position = Players.LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, self.Options.startHeight, 0)
            self.currentGrenadeObject.Velocity = startLv * 1.5
            self.currentGrenadeObject.Parent = workspace
            self.currentGrenadeObject:SetAttribute("IsOwner", true)

            -- then we just send ray hit instead
            self.RayHit(false, thrower, false, initresult, startLv * 1.5, self.currentGrenadeObject)
            return
        end

        origin = Players.LocalPlayer.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, self.Options.startHeight, 0)
        direction = (hit.Position - origin).Unit
        Replicate:FireServer("GrenadeFire", self.Options.name, origin, direction)
    end

    local castParams = thrower and Caster.getOtherParams(thrower) or Caster.getLocalParams()
    self.castBehavior.RaycastParams = castParams

    local cast = self.caster:Fire(origin, direction, self.Options.speed, self.castBehavior)
    self.currentGrenadeObject = cast.RayInfo.CosmeticBulletObject
    self.currentGrenadeObject:SetAttribute("IsOwner", not isReplicated)
end

--@summary Required Grenade Function RayHit
-- grenadeClassObject, casterPlayer, caster, result, velocity, behavior, playerLookNormal)
-- class, casterPlayer, casterThrower, result, velocity, grenade
function Molly.RayHit(_, _, _, result, velocity, grenade)

    local isOwner = grenade:GetAttribute("IsOwner")
    local explode = true
    local touchedConn

    local position = result.Position
	local normal = result.Normal
	local reflected = velocity - 2 * velocity:Dot(normal) * normal

    -- Bounce if Grenade has not landed on flat ground
    if result.Normal ~= Vector3.new(0,1,0) then
        explode = false
        grenade.CanCollide = true
        grenade.CollisionGroup = "Default"
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

    if isOwner then
        Replicate:FireServer("MollyServerExplode", position)
    end

    return
end

-- [[ MOLLY SPECIFIC FUNCTIONS ]]

--@summary Get the Params for the Molotov's Grenades.
function Molly.GetParams()
    local op = OverlapParams.new()
    op.CollisionGroup = "MollyDamageCast"
    return op
end

--@summary Create the Molotov Fire Visuals
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

--@summary Explode the Molotov on the Server
function Molly.ServerExplode(position)
    if RunService:IsClient() then return end

    -- create circle radius
    local circlepart, hitpart, animTable = Molly.CreateCirclePart(position)

    -- play pop sounds
    Sound.PlayClone(AbilityObjects.Sounds.Pop, circlepart)
    Sound.PlayClone(AbilityObjects.Sounds.InitialFire, circlepart)
    Sound.PlayClone(AbilityObjects.Sounds.Fire, circlepart)

    local t = tick() + Molly.Configuration.mollyLength
    local conn
    local charsDamaging = {}
    local charsRegisteredDamagingThisCycle = {}

    conn = RunService.Heartbeat:Connect(function()

        if not circlepart or not hitpart or tick() >= t then
            for _, v in pairs(charsDamaging) do
                v.connection:Disconnect()
            end

            -- clean up function
            Molly.ServerCleanUpParts(circlepart, hitpart, animTable)

            conn:Disconnect()
            return
        end

        local resultArray = workspace:GetPartsInPart(hitpart, Molly.GetParams())
        if #resultArray > 1 then
            for _, v in pairs(resultArray) do
                local char = v.Parent
                if not charsDamaging[char.Name] then
                    charsDamaging[char.Name] = {nextDamageTick = tick(), connection = RunService.Heartbeat:Connect(function()
                        if tick() >= charsDamaging[char.Name].nextDamageTick then
                            if not char:FindFirstChild("Humanoid") then return end
                            charsDamaging[char.Name].nextDamageTick = Molly.Configuration.damageInterval + tick()
                            char:SetAttribute("lastHitPart", "LeftFoot")
                            char:SetAttribute("lastUsedWeapon", "Ability")
                            EvoPlayer:TakeDamage(char, Molly.Configuration.damagePerInterval)
                            Sound.PlayReplicatedClone(AbilityObjects.Sounds.BurnHigh, char, true)
                            Sound.PlayReplicatedClone(AbilityObjects.Sounds.BurnLow, char, true)
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

--@summary Clean up the Molly's Fire Visuals
function Molly.ServerCleanUpParts(visualizerPart, damagerPart, animTable)
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
end

return Molly