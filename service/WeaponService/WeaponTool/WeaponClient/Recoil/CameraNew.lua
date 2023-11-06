-- New Recoil Module
-- Weapon Configuration:

-- offsetBulletStart         - Bullet that Y Offset startes to accumulate
-- offsetBulletFinal         - Bullet that Y Offset is max
-- offsetAmount              - Y Offset Max Amount in studs

-- spray patterns will still exist but will be meant for Vector only,
-- camera recoil will follow vector on the X always and on the Y until offsetBulletStart

local RunService = game:GetService("RunService")
local Math = require(game:GetService("ReplicatedStorage"):WaitForChild("lib"):WaitForChild("fc_math"))

local CameraRecoil = {}

local GLOBAL_CAM_MULT = 0.027

function CameraRecoil:init()
    self._camVar = {
        firing = false, counter = 0, processing = false,
        rupf = nil, rdpf = nil,
        us = 1/60,
        up = true, unxt = false,
        upgoal = false, upamnt = Vector3.zero, nupgoal = Vector3.zero,
        initDownMin = false,
        camRecoil = false
    }
    CameraRecoil.Connect(self)
end

function CameraRecoil:Fire(camRecoil)
    camRecoil *= GLOBAL_CAM_MULT
    camRecoil *= self._camModifier
    camRecoil = CameraRecoil.fire_applyFVMax(self, {X = camRecoil.X, Y = camRecoil.Y, Z = camRecoil.Z}, camRecoil)
    if self._camVar.processing then
        repeat task.wait() until not self._camVar.processing
    end
    self._camVar.camRecoil = camRecoil
    self._camVar.upgoal = Vector3.new(camRecoil.X, camRecoil.Y, 0)
    self._camVar.up = true
    self._camVar.counter = 0
    self._camVar.unxt = nil
    self._camVar.firing = true
end

function CameraRecoil:Connect()
    self.connection = RunService.RenderStepped:Connect(function(dt)
        if not self._camVar.firing then return end

        self._camVar.processing = true
        self._camVar.ds = self._camReset

        self._camVar.counter += dt
        self._camVar.rupf = self._camVar.camRecoil * (dt/self._camVar.us)

        if self._camVar.up then
            if self._camVar.unxt and self._camVar.unxt == "skip" then
                if self._camVar.counter >= self._camVar.us then
                    self._camVar.unxt = nil
                    self._camVar.up = false
                    self._camVar.nupgoal = self._totalRecoiledVector
                    self._camVar.upgoal = Math.vector3Abs(self._totalRecoiledVector)
                    self._camVar.upamnt = Vector3.zero
                    self._camVar.initDownMin = Vector3.new(self._camVar.camRecoil.X, self._camVar.camRecoil.Y, 0) * (dt/(self._camVar.us*2))
                end
                return
            end

            self._camVar.goalRotation = Vector3.new(self._camVar.rupf.X, self._camVar.rupf.Y, 0)
            self._camVar.upamnt += self._camVar.goalRotation

            if (math.abs(self._camVar.upgoal.X) <= math.abs(self._camVar.upamnt.X) and math.abs(self._camVar.upgoal.Y) <= math.abs(self._camVar.upamnt.Y)) then
                self._camVar.unxt = "skip"
            end
        else
            if self._camVar.initDownMin then
                self._camVar.rdpf = self._camVar.initDownMin
                self._camVar.initDownMin = false
            else
                self._camVar.rdpf = self._camVar.nupgoal * (dt/self._camVar.ds)
            end
            
            self._camVar.goalRotation = Vector3.new(-self._camVar.rdpf.X, -self._camVar.rdpf.Y, 0)
            self._camVar.upamnt += Vector3.new(math.abs(self._camVar.goalRotation.X), math.abs(self._camVar.goalRotation.Y), 0)

            if (self._camVar.upgoal.X <= self._camVar.upamnt.X and self._camVar.upgoal.Y <= self._camVar.upamnt.Y) then
                self._camVar.firing = false
            end
        end
        
        self.Camera.CFrame = self.Camera.CFrame:ToWorldSpace(CFrame.Angles(self._camVar.goalRotation.X, self._camVar.goalRotation.Y, 0))
        self._totalRecoiledVector += Vector3.new(self._camVar.goalRotation.X, self._camVar.goalRotation.Y, 0)
        self._camVar.processing = false
    end)
end

-- apply fire max to fake vector
-- return vector3
function CameraRecoil:fire_applyFVMax(fv, recoil)
    local max = self.Options.fireVectorCameraMax
    for i, v  in pairs(fv) do
        local _rec = recoil[i]
        fv[i] = _rec > 0 and math.min(_rec, max[i]) or math.max(_rec, -max[i])
    end
    return Vector3.new(fv.X, fv.Y, fv.Z)
end

return CameraRecoil