local GLOBAL_CAM_MULT = 0.027

local Math = require(game.ReplicatedStorage.lib.fc_math)
local RunService = game:GetService("RunService")

local Recoil = {}
local Viewmodel = require(script:WaitForChild("Viewmodel"))
local Pattern = require(script:WaitForChild("Pattern"))

function Recoil:init() -- Be sure to apply Vector and Camera values seperately
    self.GLOBAL_VIEWMODEL_MULT = 0.27
    self.Camera = workspace.CurrentCamera
    self.ViewmodelModule = require(self.Character:WaitForChild("ViewmodelScript"):WaitForChild("m_viewmodel"))

    Pattern.ParseSprayPattern(self.Options)

    Recoil.ResetRecoilVar(self)
    Recoil.GetKey(self, 1)
    Viewmodel.init(self)

    RunService:BindToRenderStep(self.Options.inventorySlot .. "_CamRec", Enum.RenderPriority.Camera.Value + 3, function(dt)
        Recoil.Update(self, dt)
    end)
end

function Recoil:ReparsePattern()
    Pattern.ParseSprayPattern(self.Options)
end

function Recoil:Fire(bullet)
    -- Camera & Viewmodel
    local key = Recoil.GetKey(self, bullet)
    Recoil.SetFireRecoilVar(self, key * GLOBAL_CAM_MULT * self._camModifier)
    key *= self._vecModifier
    Viewmodel.Fire(self, bullet, key)
    return key
end

function Recoil:GetKey(bullet)
    local key = Pattern.GetKey(bullet)
    Recoil.convertKeyCamValues(self, key)
    return Vector3.new(key[2], key[1], key[3])
end

function Recoil:SetFireRecoilVar(camRecoil)
    if camRecoil.X == 0 then
        camRecoil = Vector3.new(self.CamRecoil.X, camRecoil.Y, camRecoil.Z)
    end
    self.UpGoal = Vector3.new(camRecoil.X, camRecoil.Y, 0)
    self.CamRecoil = camRecoil
    self.UpAmount = Vector3.zero
    self.NupGoal = Vector3.zero
    self.Up = true
    self.Unxt = false
    self.Stop = false
end

function Recoil:ResetRecoilVar()
    self._totalRecoiledVector = Vector3.zero
    self._currentRecoilVector = Vector3.zero
    self.UpGoal = Vector3.zero
    self.UpAmount = Vector3.zero
    self.NupGoal = Vector3.zero
    self.Up = false
    self.Unxt = false
    self.Stop = true
end

function Recoil:Update(dt)
    if self.Stop then return end

    local rupf, rdpf
    local goalRotation
    local us, ds = 1/60, self._camReset

    self.processing = true
    
    if self.Up and self.Unxt and self.Unxt == "skip" then
        self.Unxt = nil
        self.Up = false
        self.NupGoal = self._totalRecoiledVector
        self.UpGoal = Math.vector3Abs(self._totalRecoiledVector)
        self.UpAmount = Vector3.zero
    end

    if self.Up then
        local rec = self.CamRecoil
        if self.Options.cameraShakeAmount then
            self.Shake = Math.absValueRandom(self.Options.cameraShakeAmount) * GLOBAL_CAM_MULT * self._camModifier
            rec = Vector3.new(
                rec.X,
                rec.Y + self.Shake,
                rec.Z
            )
        end

        rupf = rec/us
        goalRotation = Vector3.new(rupf.X, rupf.Y, 0) * dt
        if (self.UpAmount + goalRotation).Magnitude >= self.CamRecoil.Magnitude then
            goalRotation = self.CamRecoil - self.UpAmount
        end
        self.UpAmount += goalRotation

        if (math.abs(self.UpGoal.X) <= math.abs(self.UpAmount.X) and math.abs(self.UpGoal.Y) <= math.abs(self.UpAmount.Y)) then
            self.Unxt = "skip"
        end
    else
        local rec = self.NupGoal
        if self.Shake then
            self.Shake = false
        end
        
        rdpf = rec/ds
        goalRotation = Vector3.new(-rdpf.X, -rdpf.Y, 0) * dt
        self.UpAmount += Vector3.new(math.abs(goalRotation.X), math.abs(goalRotation.Y), 0)

        if (self.UpGoal.X <= self.UpAmount.X and self.UpGoal.Y <= self.UpAmount.Y) then
            self.Stop = true
        end
    end

    self.Camera.CFrame = self.Camera.CFrame:ToWorldSpace(CFrame.Angles(goalRotation.X, goalRotation.Y, 0)) --self.Camera.CFrame:ToWorldSpace()
    self._totalRecoiledVector += goalRotation
    self.processing = false
end

-- [[ UTIL ]]

function Recoil:convertKeyCamValues(key)
    self._vecModifier = key[4] or self._vecModifier
    self._camModifier = key[5] or self._camModifier
    self._camReset = key[6] or self._camReset
end

return Recoil