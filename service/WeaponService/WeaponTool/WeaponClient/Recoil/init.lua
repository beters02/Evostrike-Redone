local Recoil = {}
local Camera = require(script:WaitForChild("Camera"))
local Viewmodel = require(script:WaitForChild("Viewmodel"))
local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("lib"):WaitForChild("fc_strings"))

function Recoil:init()
    self.Player = game.Players.LocalPlayer
    self.Character = self.Player.Character or self.Player.CharacterAdded:Wait()
    self.Camera = workspace.CurrentCamera
    self.ViewmodelModule = require(self.Character:WaitForChild("ViewmodelScript"):WaitForChild("m_viewmodel"))
    self.GLOBAL_CAM_MULT = 0.027
    self.GLOBAL_VIEWMODEL_MULT = 0.27

    self._camModifier = 1
    self._vecModifier = 1
    self._camReset = 1
    self._sprayPattern = self.Options.sprayPattern
    self._lastSavedRecVec = Vector3.zero
    self._totalRecoiledVector = Vector3.zero
    self._waiting = false
    self._nextFireTime = 0
    self._currentBullet = 1

    Viewmodel.init(self)
    Recoil.GetRecoilVector3(self, Recoil.GetSprayPatternKey(self, 1), true)

    self.RecoilFire = function(currentBullet)
        return Recoil.Fire(self, currentBullet)
    end
end

function Recoil:Fire(currentBullet)
    local vecRecoil = Recoil.GetRecoilVector3(self, Recoil.GetSprayPatternKey(self, currentBullet))
    local camRecoil = Recoil.GetRecoilVector3(self, Recoil.GetSprayPatternKey(self, currentBullet), true)
    Camera.Fire(self, camRecoil)
    Viewmodel.Fire(self, currentBullet, vecRecoil)
    return vecRecoil, camRecoil
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