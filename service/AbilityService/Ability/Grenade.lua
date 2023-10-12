local Grenade = {}

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local States = require(Framework.Module.m_states)

local PlayerActionsState
if RunService:IsClient() then PlayerActionsState = States.State("PlayerActions") end

--@override
--@summary Required Ability Function Use
function Grenade:Use()

    PlayerActionsState:set(self.Player, "grenadeThrowing", self.Options.name)
    task.delay(self.Options.usingDelay, function()
        PlayerActionsState:set(self.Player, "grenadeThrowing", false)
    end)

    self:SoundUse()
    self:PlayEquipCameraRecoil()
    self:UsePost()

    -- make player hold grenade in left hand
    workspace.CurrentCamera.viewModel.LeftEquipped:ClearAllChildren()

    local grenadeClone = self.Module.Assets.Models.Grenade:Clone()
    grenadeClone.Parent = workspace.CurrentCamera.viewModel.LeftEquipped
    grenadeClone.Size = self.Options.clientGrenadeSize or grenadeClone.Size * 0.8
    CollectionService:AddTag(grenadeClone, self.Player.Name .. "_ClearOnDeath")

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
        --[[if self.Variables._equipFinishCustomSpring then
            self.Variables._equipFinishCustomSpring.Shove()
        end]]
    end)

    task.wait(self.Options.grenadeThrowDelay or 0.01)

    self:SoundThrow()

    -- grenade usage
    local hit = self.Player:GetMouse().Hit
    local startLv = self.Player.Character.HumanoidRootPart.CFrame.LookVector
    local origin = self.Player.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, self.Options.startHeight, 0)
    local direction = (hit.Position - origin).Unit
    self:FireGrenade(hit, origin, direction)
    self.RemoteFunction:InvokeServer("FireGrenadeServer", hit, origin, direction)

    -- destroy left hand clone
    grenadeClone:Destroy()
    m6:Destroy()
end

--@summary
function Grenade:PlayEquipCameraRecoil()
    --[[self.Variables.cameraLastEquipShove = Vector3.new(0.01, Math.absr(0.01), 0)
    self.Variables.cameraSpring:shove(self.Variables.cameraLastEquipShove)
    task.wait()
    self.Variables.cameraSpring:shove(-self.Variables.cameraLastEquipShove)]]
end

--@summary The Core FireGrenade function ran before FireGrenade. Not recommended to override
function Grenade:FireGrenade(hit, origin, direction)
    local cast = self.Caster:Fire(origin, direction, self.Options.speed, self.CastBehavior)
    local grenade = cast.RayInfo.CosmeticBulletObject
    grenade:SetAttribute("Owner", self.Player.Name)
    CollectionService:AddTag(grenade, "DestroyOnPlayerDied_" .. self.Player.Name)
    task.spawn(function()
        self:FireGrenadePost(hit, origin, direction, grenade)
    end)
    if RunService:IsClient() then
        self.ClientGrenade = grenade
    end
    return grenade
end

--@summary The FireGrenade function ran after FireGrenadeCore
--         This is the function you'll want to override to add custom functionality.
function Grenade:FireGrenadePost(hit, origin, direction, grenade)
    
end

--@summary The sounds played when a grenade is used (equipped before throwing)
function Grenade:SoundUse()
    Sound.PlayReplicatedClone(self.Module.Assets.Sounds.Equip, self.Player.Character.PrimaryPart)
end

--@summary The sounds played when a grenade is thrown
function Grenade:SoundThrow()
    Sound.PlayReplicatedClone(self.Module.Assets.Sounds.Throw, self.Player.Character.PrimaryPart)
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

function Grenade:RayHitCore(caster, result, segmentVelocity, cosmeticBulletObject)
    if RunService:IsClient() then
        if self.ServerGrenade then
            self.ServerGrenade.Transparency = 0
        end
        if self.ClientGrenade then
            self.ClientGrenade.Transparency = 1
        end
    else
        self:RayHit(caster, result, segmentVelocity, cosmeticBulletObject)
    end
end

-- Only runs on server
function Grenade:RayHit(caster, result, segmentVelocity, cosmeticBulletObject)
end

return Grenade