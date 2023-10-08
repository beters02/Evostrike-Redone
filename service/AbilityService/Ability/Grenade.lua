-- [[ This module contains the Base Ability Class Functions for a Grenade Ability ]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local States = require(Framework.Module.m_states)
local Replicate = ReplicatedStorage.Services.AbilityService.Events.Replicate
local Caster = require(Framework.Service.AbilityService.Caster)
local Math = require(Framework.Module.lib.fc_math)

local PlayerActionsState
if RunService:IsClient() then PlayerActionsState = States.State("PlayerActions") end

local Grenade = {
    Configuration = {
        -- data
        name = "Grenade",
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

--@override
--@summary Grenade Ability UseCore Override
function Grenade:UseCore()
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

    local grenadeClone = self.AbilityObjects.Models.Grenade:Clone()
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
        if self.Variables._equipFinishCustomSpring then
            self.Variables._equipFinishCustomSpring.Shove()
        end
    end)

    task.wait(self.Options.grenadeThrowDelay or 0.01)

    self:SoundThrow()

    -- grenade usage
    self:FireGrenadeCore(self.Player:GetMouse().Hit)

    -- destroy left hand clone
    grenadeClone:Destroy()
    m6:Destroy()
end

--@summary Custom Grenade-Only UsePost function for Use customization (Played after useDelay and before Throw)
function Grenade:UsePost()
end

--@summary
function Grenade:PlayEquipCameraRecoil()
    self.Variables.cameraLastEquipShove = Vector3.new(0.01, Math.absr(0.01), 0)
    self.Variables.cameraSpring:shove(self.Variables.cameraLastEquipShove)
    task.wait()
    self.Variables.cameraSpring:shove(-self.Variables.cameraLastEquipShove)
end

--@summary The Core FireGrenade function ran before FireGrenade. Not recommended to override
function Grenade:FireGrenadeCore(hit, isReplicated, origin, direction, thrower)
    print(self)
    if not isReplicated then
        local startLv = Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
        origin = Players.LocalPlayer.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, self.Options.startHeight, 0)
        direction = (hit.Position - origin).Unit
        Replicate:FireServer("GrenadeFire", self.Options.name, origin, direction)
    end

    local castParams = thrower and Caster.getOtherParams(thrower) or Caster.getLocalParams()
    self.castBehavior.RaycastParams = castParams

    local cast = self.caster:Fire(origin, direction, self.Options.speed, self.castBehavior)
    local grenade = cast.RayInfo.CosmeticBulletObject
    grenade:SetAttribute("IsOwner", not isReplicated)
    CollectionService:AddTag(grenade, self.Player.Name .. "_ClearOnDeath")
    self.currentGrenadeObject = grenade

    self:FireGrenadePost(hit, isReplicated, origin, direction, thrower, grenade)
end

--@summary The FireGrenade function ran after FireGrenadeCore
--         This is the function you'll want to override to add custom functionality.
function Grenade:FireGrenadePost(hit, isReplicated, origin, direction, thrower, grenade)
    
end

--@summary The sounds played when a grenade is used (equipped before throwing)
function Grenade:SoundUse()
    Sound.PlayReplicatedClone(self.AbilityObjects.Sounds.Equip, self.Player.Character.PrimaryPart)
end

--@summary The sounds played when a grenade is thrown
function Grenade:SoundThrow()
    Sound.PlayReplicatedClone(self.AbilityObjects.Sounds.Throw, self.Player.Character.PrimaryPart)
end

return Grenade