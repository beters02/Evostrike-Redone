local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RemotesLib = require(Framework.shfc_remotes.Location)
local SharedAbilityRF = ReplicatedStorage:WaitForChild("ability").remote.sharedAbilityRF
local FastCast = require(Framework.shc_fastcast.Location)

-- Store Ability Options for ease of access
local Shared = {}
Shared.AbilityOptions = {}
Shared.AbilityObjects = {}

if RunService:IsClient() then
    Shared.AbilityOptions.LongFlash = require(SharedAbilityRF:InvokeServer("Class", "LongFlash"))
    Shared.AbilityOptions.HEGrenade = require(SharedAbilityRF:InvokeServer("Class", "HEGrenade"))
else
    local AbilityClass = Framework.Ability.Location.Parent.class
    Shared.AbilityOptions.LongFlash = require(AbilityClass.LongFlash)
    Shared.AbilityOptions.HEGrenade = require(AbilityClass.HEGrenade)
end

Shared.AbilityObjects.Molly = ReplicatedStorage.ability.obj.Molly

--[[
    function InitCaster

    @return caster, castBehavior
]]
function Shared.InitCaster(character, abilityOptions, abilityObjects)
    local caster, casbeh
    caster = FastCast.new()
    casbeh = FastCast.newBehavior()
    casbeh.RaycastParams = RaycastParams.new()
    casbeh.RaycastParams.CollisionGroup = "Bullets"
    casbeh.RaycastParams.FilterDescendantsInstances = {character}
    casbeh.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    casbeh.MaxDistance = 500
    casbeh.Acceleration = Vector3.new(0, -workspace.Gravity * abilityOptions.gravityModifier, 0)
    casbeh.CosmeticBulletContainer = workspace.Temp
    casbeh.CosmeticBulletTemplate = abilityObjects.Models.Grenade
    return caster, casbeh
end

--[[
    function FireCaster
]]

function Shared.FireCaster(player, mouseHit, caster, casbeh, abilityOptions)
    local startLv = player.Character.HumanoidRootPart.CFrame.LookVector
	local origin = player.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, abilityOptions.startHeight, 0)
	local direction = (mouseHit.Position - origin).Unit
    local cast = caster:Fire(origin, direction, direction * abilityOptions.speed, casbeh)
    local bullet = cast.RayInfo.CosmeticBulletObject
    local conns = {}
    table.insert(conns, caster.LengthChanged:Connect(Shared.GrenadeOnLengthChanged))
    table.insert(conns, caster.RayHit:Connect(function(cast, result, velocity, bullet, playerLookNormal)
        if abilityOptions.abilityName == "LongFlash" then
            Shared.LongFlashRayHit(cast, result, velocity, bullet, playerLookNormal)
        elseif abilityOptions.abilityName == "Molly" then
            Shared.MollyRayHit(cast, result, bullet, Shared.AbilityObjects.Molly, direction, velocity)
        elseif abilityOptions.abilityName == "HEGrenade" then
            Shared.HEGrenadeRayHit(cast, result, bullet, direction, velocity)
        end
    end))
    table.insert(conns, caster.CastTerminating:Connect(function()
        for i, v in pairs(conns) do
            v:Disconnect()
        end
    end))
    --[[if abilityOptions.abilityName == "Molly" then -- rotating doesnt work :/
        if RunService:IsClient() then
            table.insert(conns, RunService.RenderStepped:Connect(function(dt)
                bullet.CFrame *= CFrame.Angles(45, 45, 45)
            end))
        end
    end]]
    return bullet, conns
end

--[[
    function GrenadeOnLengthChanged
]]

function Shared.GrenadeOnLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then 
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0, 0, -(length - bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
	end
end

--[[
    function LongFlashRayHit
]]

function Shared.GetMollyParams()
    local op = OverlapParams.new()
    op.CollisionGroup = "MollyDamageCast"
    return op
end

function Shared.CreateMollyCirclePart(grenade, abilityObjects, position)
    local vispart = abilityObjects.Models.MollyPreset:Clone()
    vispart.Size = Vector3.new(0.1, 15, 15)
    vispart.CFrame = CFrame.new(position or grenade.CFrame.Position) * CFrame.Angles(0,0,math.pi*-.5)
    vispart.CollisionGroup = "Bullets"
    vispart.Parent = workspace.Temp

    local hitpart = vispart:Clone()
    hitpart.Size = Vector3.new(10, hitpart.Size.Y, hitpart.Size.Z)
    hitpart.Parent = workspace.Temp
    hitpart.Transparency = 1
    return vispart, hitpart
end

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

function Shared.LongFlashRayHit(cast, result, velocity, grenadeModel, playerLookNormal)
    local LongFlash = Shared.AbilityOptions.LongFlash
    local normal = result.Normal
    local outDistance = LongFlash.anchorDistance
    task.spawn(function()
        local pos = grenadeModel.Position + (normal * outDistance)
        local collRes = workspace:Raycast(grenadeModel.Position, normal * outDistance)
        if collRes then pos = collRes.Position end

        -- set emitter variables
        for i, v in pairs(grenadeModel:GetChildren()) do
            if not v:IsA("ParticleEmitter") or not v.Name == "Spark" then continue end
            v = v :: ParticleEmitter
            v.Speed = NumberRange.new(10, 20)
            v.Lifetime = NumberRange.new(0.1, 0.1)
            v.Rate = 30
        end

        -- pop animation
        local popt = TweenService:Create(grenadeModel, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true), {Size = grenadeModel.Size * 10})
        local poptl = TweenService:Create(grenadeModel.PointLight, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true), {Range = 60})

        -- send grenade out reflected
        local t = TweenService:Create(grenadeModel, TweenInfo.new(LongFlash.anchorTime), {Position = pos})
        t:Play()
        t.Completed:Wait()

        -- once the grenade has reached its reflection time (anchor time), wait another small amount of times so players can react.
        grenadeModel.Anchored = true
        task.wait(LongFlash.popTime)
        
        -- only register flash popping if server
        if RunService:IsServer() then
            LongFlash.FlashPop(grenadeModel)
            task.wait()
            grenadeModel:Destroy()
        else
            popt:Play()
            poptl:Play()
            popt.Completed:Wait()

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

        -- destroy bullet after flashpop
        
    end)
end

--[[
    function MollyRayHit
]]

function Shared.MollyRayHit(cast, result, grenade, abilityObjects, direction, velocity)

    local explode = true
    local touchedConn
    local position = grenade.CFrame.Position

    -- unit the normal (i its already normalized idk)
	local normal = result.Normal
	-- reflect the vector
	local reflected = velocity - 2 * velocity:Dot(normal) * normal

    if result.Normal ~= Vector3.new(0,1,0) then
        explode = false

        grenade.CanCollide = true
        grenade.Velocity = reflected * 0.3
        task.wait()

        touchedConn = grenade.Touched:Connect(function(part)
            local p = RaycastParams.new()
            p.FilterDescendantsInstances = {grenade}
            p.FilterType = Enum.RaycastFilterType.Exclude
            local g = workspace:Raycast(grenade.Position, Vector3.new(0,-1,0) * 2, p)
            print(g)
            if not g then return end

            position = g.Position
            explode = true
            touchedConn:Disconnect()
            print(part.Name)
        end)
    end

    if not explode then repeat task.wait() until explode end

    grenade:Destroy()

    if RunService:IsClient() then
        return
    end

    -- create circle radius
    local circlepart, hitpart = Shared.CreateMollyCirclePart(grenade, abilityObjects, position)

    local t = tick() + 3 --(abilityOptions.mollyLength)
    local conn
    local charsDamaging = {}
    local charsRegisteredDamagingThisCycle = {}

    conn = RunService.Heartbeat:Connect(function()
        if not circlepart or not hitpart or tick() >= t then
            for i, v in pairs(charsDamaging) do
                v.connection:Disconnect()
            end
            if circlepart then circlepart:Destroy() end
            if hitpart then hitpart:Destroy() end
            return
        end

        local resultArray = workspace:GetPartsInPart(hitpart, Shared.GetMollyParams())
        if #resultArray > 1 then
            for i, v in pairs(resultArray) do
                local char = v.Parent
                if not charsDamaging[char.Name] then
                    charsDamaging[char.Name] = {nextDamageTick = tick(), connection = RunService.Heartbeat:Connect(function()
                        if tick() >= charsDamaging[char.Name].nextDamageTick then
                            charsDamaging[char.Name].nextDamageTick = 0.5 + tick()
                            char.Humanoid:TakeDamage(10)
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

--[[

]]

function HEGrenadeUpdate(grenade, num)
    local p = RaycastParams.new()
    p.FilterDescendantsInstances = {grenade}
    p.FilterType = Enum.RaycastFilterType.Exclude
    local g = workspace:Raycast(grenade.Position, Vector3.new(0,-1,0) * 2, p)

    if g then
        grenade.Velocity *= num.Value
        return
    end

    grenade.Velocity = Vector3.new(grenade.Velocity.X * num.Value, grenade.Velocity.Y, grenade.Velocity.Z * num.Value)
end

function Shared.HEGrenadeRayHit(cast, result, grenade, direction, velocity)

    print('he grenade worked')

    local explodeLength = Shared.AbilityOptions.HEGrenade.explodeLength
    
    -- unit the normal (i its already normalized idk)
	local normal = result.Normal
	-- reflect the vector
	local reflected = velocity - 2 * velocity:Dot(normal) * normal
    local conn

    grenade.CanCollide = true
    grenade.Velocity = reflected * 0.3
    task.wait()

    local num = Instance.new("NumberValue")
    num.Parent = ReplicatedStorage.temp
    num.Value = 1
    local tween = TweenService:Create(num, TweenInfo.new(explodeLength), {Value = 0})
    local e = tick() + explodeLength
    tween:Play()

    if RunService:IsClient() then
        conn = RunService.RenderStepped:Connect(function()
            if tick() >= e then
                print("BOOM")
                grenade:Destroy()
                conn:Disconnect()
            end
            
            HEGrenadeUpdate(grenade, num)
        end)
    else
        conn = RunService.Heartbeat:Connect(function()
            if tick() >= e then
                print("BOOM")
                grenade:Destroy()
                conn:Disconnect()
            end
    
            HEGrenadeUpdate(grenade, num)
        end)
    end
    

end

return Shared