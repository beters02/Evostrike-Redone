local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local FastCast = require(Framework.shc_fastcast.Location)
-- Store Ability Options for ease of access
local Shared = {}
Shared.AbilityOptions = {}
Shared.AbilityObjects = {}

if RunService:IsClient() then
    Shared.AbilityOptions.LongFlash = require(ReplicatedStorage.ability.class.LongFlash)
    Shared.AbilityOptions.HEGrenade = require(ReplicatedStorage.ability.class.HEGrenade)
    Shared.AbilityOptions.Molly = require(ReplicatedStorage.ability.class.Molly)
else
    local AbilityClass = ReplicatedStorage.ability.class
    Shared.AbilityOptions.LongFlash = require(AbilityClass.LongFlash)
    Shared.AbilityOptions.HEGrenade = require(AbilityClass.HEGrenade)
    Shared.AbilityOptions.Molly = require(AbilityClass.Molly)
end

Shared.AbilityObjects.Molly = ReplicatedStorage.ability.obj.Molly
Shared.AbilityObjects.LongFlash = ReplicatedStorage.ability.obj.LongFlash

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
    table.insert(conns, caster.RayHit:Connect(function(c, result, velocity, b, playerLookNormal)
        if abilityOptions.abilityName == "LongFlash" then
            Shared.LongFlashRayHit(cast, result, velocity, bullet, playerLookNormal)
        elseif abilityOptions.abilityName == "Molly" then
            Shared.MollyRayHit(cast, result, bullet, Shared.AbilityObjects.Molly, direction, velocity)
        elseif abilityOptions.abilityName == "HEGrenade" then
            Shared.HEGrenadeRayHit(cast, result, bullet, direction, velocity)
        elseif abilityOptions.abilityName == "Satchel" then
            Shared.SatchelRayHit(cast, result, bullet, player)
        end
    end))
    table.insert(conns, caster.CastTerminating:Connect(function()
        for i, v in pairs(conns) do
            v:Disconnect()
        end
    end))
    if RunService:IsServer() then
        -- destroy cosmetic particle effects of grenade
        -- unless KeepOnServer attribute is specified
        for i, v in pairs(bullet:GetChildren()) do
            if not v:GetAttribute("KeepOnServer") then
                v:Destroy()
            end
        end
    end
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

--[[
]]

function Shared.SatchelRayHit(cast, result, grenade, caster)
    
    if RunService:IsServer() then
        Debris:AddItem(grenade, 5)
        return
    end

    grenade.Anchored = true

    if Players.LocalPlayer == caster then
        caster.Character["AbilityFolder_Satchel"].Remotes.AbilityBindableEvent:Fire("ConnectSatchel")
        print('EVENT FIRED')
    end

end

return Shared