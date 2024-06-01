local GLOBAL_CAM_MULT = 0.027

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("lib"):WaitForChild("fc_strings"))
local Math = require(game.ReplicatedStorage.lib.fc_math)
local RunService = game:GetService("RunService")
local VMSprings = require(Framework.Module.lib.c_vmsprings)

local Recoil = {}
local Viewmodel = require(script:WaitForChild("Viewmodel"))

function Recoil:init() -- Be sure to apply Vector and Camera values seperately
    self.GLOBAL_VIEWMODEL_MULT = 0.27
    self.Camera = workspace.CurrentCamera
    self.ViewmodelModule = require(self.Character:WaitForChild("ViewmodelScript"):WaitForChild("m_viewmodel"))
    self._sprayPattern = self.Options.sprayPattern
    
    Recoil.ResetRecoilVar(self)
    Recoil.GetKey(self, 1)
    Viewmodel.init(self)

    RunService:BindToRenderStep(self.Options.inventorySlot .. "_CamRec", Enum.RenderPriority.Camera.Value + 3, function(dt)
        Recoil.Update(self, dt)
    end)
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
    local key = Recoil.parseRecoilRuntimeString(self, {}, self._sprayPattern[bullet])
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
        
    --dt = self._stepDT or dt
    
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
        --self:UpdateOrigin(dt)

        local rec = self.NupGoal
        --[[if self.Shake then
            rec = Vector3.new(
                rec.X,
                rec.Y - self.Shake,
                rec.Z
            )
            self.Shake = false
        end]]
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

-- returns the vector3 to be added to vector recoil
-- the recoil vector table is Up, Side instead of Side, Up
function Recoil:GetRecoilVector3(patternKey: table, isCamera: boolean): Vector3
    local parsedKey
    local recoil
    local rVec3
    local rmod
    local rcam

    -- parse runtime strings (absr)
	parsedKey = Recoil.parseRecoilRuntimeString(self, {}, patternKey)

    -- gather recoil var
    -- this changes the table to Up, Side.
    recoil = Vector3.new(parsedKey[2], parsedKey[1], parsedKey[3])

    rmod = self._vecModifier
    rVec3 = Vector3.new(recoil.X * rmod, recoil.Y * rmod, recoil.Z * rmod)
    rcam = Recoil.updateRecoilVectorTableAsCamera(self, recoil, parsedKey)
    
    -- set camera variables
    if isCamera then
        recoil = rcam
        self._lastSavedRecVec = recoil
    else
        -- grab the vec modifier after cam var update incase mod was updated
        recoil = rVec3
    end

    return recoil, rmod, rcam
end

function Recoil:GetSprayPatternKey(bullet)
    return self._sprayPattern[bullet]
end

function Recoil:parseRecoilDuringString(str)
    if string.match(str, "absr") then -- Absolute Value Random (1, -1)
        local chars = Strings.seperateToChar(string.gsub(str, "absr", ""))

        local numstr = ""
        for i, v in chars do
            if tonumber(v) or tostring(v) == "." then
                numstr = numstr .. v
            end
        end

        return (math.random(0, 1) == 1 and 1 or -1) * tonumber(numstr)
    end
end

function Recoil:parseRecoilRuntimeString(tableCombine: table, patternKey: table)
    local new = tableCombine or {}
    for i, v in pairs(patternKey) do
		if type(v) == "string" then
			new[i] = Recoil.parseRecoilDuringString(self, v)
		else
			new[i] = v
		end
	end
    return new
end

function Recoil:convertKeyCamValues(key)
    self._vecModifier = key[4] or self._vecModifier
    self._camModifier = key[5] or self._camModifier
    self._camReset = key[6] or self._camReset
end

-- pass in the recoil Vector3 and ensure the Y value will not be 0
-- as well as set the classes modifiers to the values in the given key
function Recoil:updateRecoilVectorTableAsCamera(recoil, parsedKey): Vector3
    -- if we are recoiling on the camera, do not add Recoil Vector values.
    local _fv = {X = recoil.X, Y = recoil.Y, Z = recoil.Z} -- fake vector
    for i, v in pairs(_fv) do
        if v == 0 then _fv[i] = self._lastSavedRecVec[i] end
    end

    self._vecModifier = parsedKey[4] or self._vecModifier
    self._camModifier = parsedKey[5] or self._camModifier
    self._camReset = parsedKey[6] or self._camReset
    return Vector3.new(_fv.X, _fv.Y, _fv.Z)
end

return Recoil