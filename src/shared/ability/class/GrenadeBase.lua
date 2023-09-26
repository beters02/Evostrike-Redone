local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.shm_sound.Location)
local States = require(Framework.shm_states.Location)
local Math = require(Framework.shfc_math.Location)
local Grenades = require(ReplicatedStorage.Modules.Grenades)
local GrenadeRemotes = ReplicatedStorage.Modules.Grenades.Remotes
local GrenadeTypes = Grenades.Types
local Players = game:GetService("Players")

local Grenade = {
    -- useage
    grenadeThrowDelay = 0.2,

    -- grenade
    acceleration = 10,
    speed = 150,
    gravityModifier = 0.2,
    startHeight = 2,

    -- animation / holding
    clientGrenadeSize = nil,
    grenadeVMOffsetCFrame = CFrame.Angles(0,math.rad(80),0) + Vector3.new(0, 0, 0.4), -- if you have a custom animation already, set this to false
    throwAnimFadeTime = 0.18,
    throwFinishSpringShove = Vector3.new(-0.4, -0.5, 0.2),
}

function Grenade:Use()

    -- set state var
    States.SetStateVariable("PlayerActions", "grenadeThrowing", self.abilityName)
    task.delay(self.usingDelay, function()
        States.SetStateVariable("PlayerActions", "grenadeThrowing", false)
    end)

    -- play equip sound
    Sound.PlayReplicatedClone(self._sounds.Equip, self.player.Character.PrimaryPart)

    -- play equip camera recoil
    self:PlayEquipCameraRecoil()

    -- make player hold grenade in left hand
    workspace.CurrentCamera.viewModel.LeftEquipped:ClearAllChildren()
    local grenadeClone = self.abilityObjects.Models.Grenade:Clone()
    grenadeClone.Parent = workspace.CurrentCamera.viewModel.LeftEquipped
    
    if self.clientGrenadeSize then
        grenadeClone.Size = self.clientGrenadeSize
    else
        grenadeClone.Size *= 0.8
    end

    local leftHand = workspace.CurrentCamera.viewModel.LeftHand
    local m6 = leftHand:FindFirstChild("LeftGrip")
    if m6 then m6:Destroy() end

    m6 = Instance.new("Motor6D", leftHand)
    m6.Name = "LeftGrip"
    m6.Part0 = leftHand
    m6.Part1 = grenadeClone

    if self.grenadeVMOffsetCFrame then
        m6.C0 = self.grenadeVMOffsetCFrame
    end

    -- play throw animation
    self._animations.throw:Play(self.throwAnimFadeTime or 0.18)
    self._animations.serverthrow:Play(self.throwAnimFadeTime or 0.18)

    -- equip finish
    task.delay(self._animations.throw.Length + ((self.throwAnimFadeTime or 0.18)*1.45), function()
        if self._equipFinishCustomSpring then
            self._equipFinishCustomSpring.Shove()
        end
    end)

    task.wait(self.grenadeThrowDelay or 0.01)

    -- play throw sound
    Sound.PlayReplicatedClone(self._sounds.Throw, self.player.Character.PrimaryPart)

    -- play use camera recoil & stop equip recoil
    --self:StopEquipCameraRecoil()
    self:UseCameraRecoil()

    -- long flash does CanUse on the server via remoteFunction: ThrowGrenade
    local hit = self.player:GetMouse().Hit

    -- grenade usage
    --local used = self.remoteFunction:InvokeServer("ThrowGrenade", hit)
    local canUse = self.remoteFunction:InvokeServer("CanUse")
    if canUse then
        self:FireGrenade(hit)
    end

    -- destroy left hand clone
    grenadeClone:Destroy()
    m6:Destroy()
end

function Grenade:PlayEquipCameraRecoil()
    self.cameraLastEquipShove = Vector3.new(0.01, Math.absr(0.01), 0)
    self.cameraSpring:shove(self.cameraLastEquipShove)
    task.wait()
    self.cameraSpring:shove(-self.cameraLastEquipShove)
end

function Grenade:StopEquipCameraRecoil()
    self.cameraSpring:shove(-self.cameraLastEquipShove)
end

return Grenade