local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.shm_sound.Location)
local States = require(Framework.shm_states.Location)
local Math = require(Framework.shfc_math.Location)

local Grenade = {}

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
    grenadeClone.Size *= 0.8

    local leftHand = workspace.CurrentCamera.viewModel.LeftHand
    local m6 = leftHand:FindFirstChild("LeftGrip")
    if m6 then m6:Destroy() end

    m6 = Instance.new("Motor6D", leftHand)
    m6.Name = "LeftGrip"
    m6.Part0 = leftHand
    m6.Part1 = grenadeClone
    m6.C0 = CFrame.Angles(0,math.rad(80),0)

    -- play throw animation
    self._animations.throw:Play()
    print('played!')
    task.wait(self.grenadeThrowDelay or 0.01)

    -- play throw sound
    Sound.PlayReplicatedClone(self._sounds.Throw, self.player.Character.PrimaryPart)

    -- play use camera recoil & stop equip recoil
    --self:StopEquipCameraRecoil()
    self:UseCameraRecoil()

    -- long flash does CanUse on the server via remoteFunction: ThrowGrenade
    local hit = self.player:GetMouse().Hit
    local used = self.remoteFunction:InvokeServer("ThrowGrenade", hit)

    -- destroy left hand clone once grenade is thrown
    grenadeClone:Destroy()
    m6:Destroy()

    -- update client uses
    if used then
        self.uses -= 1
    end
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