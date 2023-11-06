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

function CameraRecoil:Fire(camRecoil)
    camRecoil *= self.GLOBAL_CAM_MULT
    camRecoil *= self._camModifier
    --camRecoil = CameraRecoil.fire_applyFVMax(self, {X = camRecoil.X, Y = camRecoil.Y, Z = camRecoil.Z}, camRecoil)

    CameraRecoil.StopRecoil(self)

    local rupf, rdpf
    local lastDT
    local stop = false
    local counter = 0
    local us, ds = 1/60, self._camReset
    local up, unxt = true, false
    local upgoal, upamnt, nupgoal = Vector3.new(camRecoil.X, camRecoil.Y, 0), Vector3.zero, Vector3.zero

    self.connection = true
    RunService:BindToRenderStep(self.Name .. "_CamRec", Enum.RenderPriority.Camera.Value + 3, function(dt)
        if stop then RunService:UnbindFromRenderStep(self.Name .. "_CamRec") end
        self.processing = true
        
        dt = self._stepDT or dt
        counter += dt
        
        if up and unxt and unxt == "skip" then
            unxt = nil
            up = false
            nupgoal = self._totalRecoiledVector
            upgoal = Math.vector3Abs(self._totalRecoiledVector)
            upamnt = Vector3.zero
        end

        if up then
            rupf = camRecoil/us
            goalRotation = Vector3.new(rupf.X, rupf.Y, 0) * dt
            upamnt += goalRotation

            if (math.abs(upgoal.X) <= math.abs(upamnt.X) and math.abs(upgoal.Y) <= math.abs(upamnt.Y)) then
                unxt = "skip"
            end
        else
            rdpf = nupgoal/ds
            goalRotation = Vector3.new(-rdpf.X, -rdpf.Y, 0) * lastDT
            upamnt += Vector3.new(math.abs(goalRotation.X), math.abs(goalRotation.Y), 0)

            if (upgoal.X <= upamnt.X and upgoal.Y <= upamnt.Y) then
                stop = true
            end
        end

        lastDT = dt

        self.Camera.CFrame = self.Camera.CFrame:ToWorldSpace(CFrame.Angles(goalRotation.X, goalRotation.Y, 0)) --self.Camera.CFrame:ToWorldSpace()
        self._totalRecoiledVector += goalRotation
        self.processing = false
    end)
end

function CameraRecoil:StopRecoil()
    if self.connection then
        if self.processing then repeat task.wait() until not self.processing end
        self.connection = false
        RunService:UnbindFromRenderStep(self.Name .. "_CamRec")
    end
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