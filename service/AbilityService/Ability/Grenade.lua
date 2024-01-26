local Grenade = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local States = require(Framework.Module.States)

local PlayerActionsState
if RunService:IsClient() then PlayerActionsState = States:Get("PlayerActions") end

-- [[ Ability ]]

function Grenade:Use()
    PlayerActionsState:set(self.Player, "grenadeThrowing", self.Options.name)
    task.delay(self.Options.usingDelay, function()
        PlayerActionsState:set(self.Player, "grenadeThrowing", false)
    end)

    local leftGrenade, leftMotor = self:CreateLeftHandModel()

    self:SoundUse()
    self:PlayEquipCameraRecoil()
    self:UsePost()
    self:PlayThrowAnimation()

    task.delay(self:GetFinishWait(), function()
        self:PlayEquipFinishCamAnimation()
    end)

    task.wait(self.Options.grenadeThrowDelay or 0.01)

    self:SoundThrow()
    self:FireGrenadePre()
    
    leftGrenade:Destroy()
    leftMotor:Destroy()
end

function Grenade:UsePost()
    
end

function Grenade:PlayEquipCameraRecoil()
    --[[self.Variables.cameraLastEquipShove = Vector3.new(0.01, Math.absr(0.01), 0)
    self.Variables.cameraSpring:shove(self.Variables.cameraLastEquipShove)
    task.wait()
    self.Variables.cameraSpring:shove(-self.Variables.cameraLastEquipShove)]]
end

function Grenade:CreateLeftHandModel()
    local vm = workspace.CurrentCamera.viewModel
    vm.LeftEquipped:ClearAllChildren()

    local grenadeClone = self.Module.Assets.Models.Grenade:Clone()
    grenadeClone.Parent = vm.LeftEquipped
    grenadeClone.Size = self.Options.clientGrenadeSize or grenadeClone.Size * 0.8
    CollectionService:AddTag(grenadeClone, self.Player.Name .. "_ClearOnDeath")

    local leftHand = vm.LeftHand
    local m6 = leftHand:FindFirstChild("LeftGrip")
    if m6 then m6:Destroy() end
    m6 = Instance.new("Motor6D", leftHand)
    m6.Name = "LeftGrip"
    m6.Part0 = leftHand
    m6.Part1 = grenadeClone
    if self.Options.grenadeVMOffsetCFrame then m6.C0 = self.Options.grenadeVMOffsetCFrame end
    return grenadeClone, m6
end

-- [[ Grenade ]]

function Grenade:FireGrenadePre()
    local hit = self.Player:GetMouse().Hit
    local startLv = self.Player.Character.HumanoidRootPart.CFrame.LookVector
    local origin = self.Player.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, self.Options.startHeight, 0)
    local direction = (hit.Position - origin).Unit
    self.RemoteFunction:InvokeServer("FireGrenadeServer", hit, origin, direction)
end

--@summary The FireGrenade Middleware function. Not recommended to override
function Grenade:FireGrenade(hit, origin, direction)

    -- grenade speed/direction are directly affected by player move speed/direction
    local speed = self.Options.speed
    local pvel = self.Player.Character.HumanoidRootPart.Velocity
    if pvel.Magnitude > 2 then
        --speed = ((speed * direction.Unit) + pvel).Magnitude
        direction += pvel.Unit/3
    end

    local cast = self.Caster:Fire(origin, direction, speed, self.CastBehavior)
    local grenade = cast.RayInfo.CosmeticBulletObject
    CollectionService:AddTag(grenade, "DestroyOnPlayerDied_" .. self.Player.Name)
    task.spawn(function()
        self:FireGrenadePost(hit, origin, direction, grenade)
    end)
    --grenade.Anchored = true -- helps lessen the spinning
    return grenade
end

--@summary ran after FireGrenadeCore
--         This is the function you'll want to override to add custom functionality.
function Grenade:FireGrenadePost(hit, origin, direction, grenade)
    
end

--[[ Fast Cast ]]

--@summary RayHit Middleware
function Grenade:RayHitCore(caster, result, segmentVelocity, cosmeticBulletObject)
    self:RayHit(caster, result, segmentVelocity, cosmeticBulletObject)
end

function Grenade:RayHit(caster, result, segmentVelocity, cosmeticBulletObject)
end

function Grenade:LengthChanged(_, lastPoint, direction, length, velocity, bullet) -- cast, lastPoint, direction, length, velocity, bullet
    if bullet then
        local bulletLength = bullet.Size.Z/2
        local offset = CFrame.new(0, 0, -(length - bulletLength))
        bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
    end
end

function Grenade:CastTerminating()
    
end

function Grenade:GetRaycastParams()
    local params = RaycastParams.new()
    params.CollisionGroup = "Grenades"
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {self.Player.Character}
    if RunService:IsClient() then
        table.insert(params.FilterDescendantsInstances, workspace.CurrentCamera)
    end
    return params
end

-- [[ Animation ]]
function Grenade:PlayThrowAnimation()
    self.Animations.throw:Play(self.Options.throwAnimFadeTime or 0.18)
    self.Animations.serverthrow:Play(self.Options.throwAnimFadeTime or 0.18)
end

function Grenade:PlayEquipFinishCamAnimation()
    --[[if self.Variables._equipFinishCustomSpring then
        self.Variables._equipFinishCustomSpring.Shove()
    end]]
end

function Grenade:GetFinishWait()
    return self.Animations.throw.Length + ((self.Options.throwAnimFadeTime or 0.18)*1.45)
end

-- [[ Sound ]]
--@summary The sounds played when a grenade is used (equipped before throwing)
function Grenade:SoundUse()
    Sound.PlayReplicatedClone(self.Module.Assets.Sounds.Equip, self.Player.Character.PrimaryPart)
end

--@summary The sounds played when a grenade is thrown
function Grenade:SoundThrow()
    Sound.PlayReplicatedClone(self.Module.Assets.Sounds.Throw, self.Player.Character.PrimaryPart)
end

return Grenade