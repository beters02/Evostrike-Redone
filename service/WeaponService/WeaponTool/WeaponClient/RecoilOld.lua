-- [[ FrameworkType: FunctionContainer ]]
--[[


    @summary
    This is a FunctionContainer that is binded to the cameraObject class upon creation.

]]

local Recoil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local Math = require(Framework.Module.lib.fc_math)

local sharedWeaponFunctions = require(Framework.shfc_sharedWeaponFunctions.Location)

--[[ MAIN ]]

function Recoil:FireRecoil(currentBullet)

    -- || Resolve: Inconsistent Feeling Camera Recoil at Low FPS
    -- Schedule recoil

    -- recoil is already scheduled
    --if self.weaponVar._waiting then return end

    -- recoil not scheduled and debounce active
    --[[if self.weaponVar._localDebounce and tick() < self.weaponVar._localDebounce then
        self.weaponVar._waiting = true

        -- schedule recoil here
        repeat task.wait() until tick() >= self.weaponVar._localDebounce

        self.weaponVar._waiting = false
    end]]
    -- ||

    -- || Resolve Camera Spray Patterns relying on a max instead of accurately represented values
    local globalCamMult = 0.03
    --

    -- set debounce to active
    self.weaponVar._localDebounce = tick() + (self.weaponVar.options.fireRate - 0.002)

    -- update the classes current bullet
    self.weaponVar.currentBullet = currentBullet

    -- init camera var
    local recoilvec
    local vecrecoilvec
    local recfv
    local rupf
    local rdpf
    local ui
    local di
    local up
    local lerpTime
    local stop
    local t
    local unxt
    local dnxt
    local diff
    local counter
    
    -- init recoilvec
    vecrecoilvec = self:getRecoilVector3(self:getSprayPatternKey(), true) * globalCamMult

    recoilvec = vecrecoilvec * self.weaponVar.camModifier
    recfv = {X = recoilvec.X, Y = recoilvec.Y, Z = recoilvec.Z} -- do this for easy editing
    ui = 1 -- default up iterations
    local us = 1/60
    di = 12 -- default down iterations

    -- apply max
    recoilvec = self:fire_applyFVMax(recfv, recoilvec)
    
    -- set recoil up per frame
    rupf = recoilvec * 1/ui

    -- stop currently running fire thread if one exists
    self:StopCurrentRecoilThread()

    -- set camera var
    stop = false
    t = tick()
    unxt = t
    dnxt = t
    diff = 1
    up = true
    counter = 0
    local upgoal = Vector3.new(recoilvec.X, recoilvec.Y, 0)
    local upamnt = Vector3.zero
    local startDT = false

    self:FireSpringRecoil(currentBullet, vecrecoilvec)

    -- init camera recoil custom lerp
    self.connection = RunService.RenderStepped:Connect(function(dt)
        stop = stop
        if stop then
            self.connection:Disconnect()
        end

        t = tick()

        if not startDT then
            startDT = dt
        end

        rupf = recoilvec/(ui * math.max(1, startDT/us))
        rdpf = self.weaponVar.totalRecoiledVector/(di * math.max(1, startDT/us))

        counter += dt

        -- camera recoil up
        if up then
            if unxt and unxt == "skip" then
                if counter >= us then
                    unxt = nil
                    up = false
                    dnxt = t
                    upgoal = self.weaponVar.totalRecoiledVector
                    upgoal = Vector3.new(math.abs(upgoal.X), math.abs(upgoal.Y), math.abs(upgoal.Z))
                    upamnt = Vector3.zero
                    startDT = dt
                end
                return
            end

            -- set lerp time to upspeed --TODO: self.weaponVar.options.cameraUpSpeed or 0.03
            lerpTime = 1/60

            -- set goal rotation (update with dt)
            goalRotation = Vector3.new(rupf.X, rupf.Y, 0)
            upamnt += goalRotation

            if (math.abs(upgoal.X) <= math.abs(upamnt.X) and math.abs(upgoal.Y) <= math.abs(upamnt.Y)) then
                unxt = "skip"
            end
        else
            -- set lerp time to camreset
            lerpTime = self.weaponVar.camReset
            lerpTime += lerpTime - (lerpTime * dt * 60)

            -- set down recoil vector based on the total recoiled vector amount which is set in the final update phase
            --rdpf = self.weaponVar.totalRecoiledVector/di

            -- set rot
            goalRotation = Vector3.new(-rdpf.X, -rdpf.Y, 0)
            upamnt += Vector3.new(math.abs(goalRotation.X), math.abs(goalRotation.Y), 0)

            if (upgoal.X <= upamnt.X and upgoal.Y <= upamnt.Y) then
                stop = true
            end
        end
        
        self.camera.CFrame = self.camera.CFrame:ToWorldSpace(CFrame.Angles(goalRotation.X, goalRotation.Y, 0))
        self.weaponVar.totalRecoiledVector += Vector3.new(goalRotation.X, goalRotation.Y, 0)
    end)
end

function Recoil:StopCurrentRecoilThread()
    if self.connection then
        self.weaponVar.stopSwitch = true
        self.connection:Disconnect()
        task.wait()
    end
end

function Recoil:FireSpringRecoil(currentBullet, recoilValues)
    if currentBullet == 1 then
        self.weaponVar.totalPos = Vector3.zero
        self.weaponVar.totalRotUp = Vector3.zero
        self.weaponVar.totalRotSide = Vector3.zero
        self.lastRotUp = 0
        self.lastRotSide = 0
        self.lastPos = 0
    end

    -- | Update Spring Variables |
    self:ClimbPosSpring(recoilValues, self.FirePosSpring.Properties)
    self:ClimbRotSideSpring(recoilValues, self.FireRotSideSpring.Properties)
    self:ClimbRotSideSpring(recoilValues, self.FireRotUpSpring.Properties)

    -- | Shove Springs |
    self.FirePosSpring.Spring:shove(self.weaponVar.totalPos)
    self.FireRotSideSpring.Spring:shove(self.weaponVar.totalRotSide)
    self.FireRotUpSpring.Spring:shove(self.weaponVar.totalRotUp)
end

-- we don't want the gun to keep climbing after a point
-- we could just clamp but thats a band aid fix since we want guns to feel different
-- recoil values returns the pos of the bullet. if Y pos was same as before, that means we didnt climb.
function Recoil:ClimbPosSpring(recoil, properties)
    if self.weaponVar.lastPos ~= recoil.X then
        self.weaponVar.totalPos += Vector3.new(0, math.clamp(recoil.X, properties.min.Y, properties.max.Y), 0) * properties.multiplier * self.weaponVar.camModifier
    end
    self.weaponVar.lastPos = recoil.X
end

function Recoil:ClimbRotUpSpring(recoil, properties)
    if self.weaponVar.lastRotUp ~= recoil.X then
        self.weaponVar.totalRotUp += Vector3.new(recoil.X, 0, 0) * properties.multiplier * self.weaponVar.camModifier
    end
    self.weaponVar.lastRotUp = recoil.X
end

function Recoil:ClimbRotSideSpring(recoil, properties)
    if self.weaponVar.lastRotSide ~= -recoil.Y then
        self.weaponVar.totalRotSide += Vector3.new(0, -recoil.Y, 0) * properties.multiplier * self.weaponVar.camModifier
    end
    self.weaponVar.lastRotSide = -recoil.Y
end

-- [[ UTIL ]]

function Recoil:parseRecoilRuntimeString(tableCombine: table, patternKey: table)
    local new = tableCombine or {}
    for i, v in pairs(patternKey) do
		if type(v) == "string" then
			new[i] = sharedWeaponFunctions.duringStrings(v)
		else
			new[i] = v
		end
	end
    return new
end

-- returns the spray pattern table key for the current bullet
function Recoil:getSprayPatternKey()
	return self.weaponVar.options.sprayPattern[self.weaponVar.currentBullet]
end

-- pass in the recoil Vector3 and ensure the Y value will not be 0
-- as well as set the classes modifiers to the values in the given key
function Recoil:updateRecoilVectorTableAsCamera(recoil, parsedKey): Vector3
    -- if we are recoiling on the camera, do not add Recoil Vector values.
    local _fv = {X = recoil.X, Y = recoil.Y, Z = recoil.Z} -- fake vector
    for i, v in pairs(_fv) do
        if v == 0 then _fv[i] = self.weaponVar.lastSavedRecVec[i] end
    end

    self.weaponVar.vecModifier = parsedKey[4] or self.weaponVar.vecModifier
    self.weaponVar.camModifier = (parsedKey[5] or self.weaponVar.camModifier)
    self.weaponVar.camReset = parsedKey[6] or self.weaponVar.camReset
    return Vector3.new(_fv.X, _fv.Y, _fv.Z), self.weaponVar.camReset
end

-- returns the vector3 to be added to vector recoil
-- the recoil vector table is Up, Side instead of Side, Up
function Recoil:getRecoilVector3(patternKey: table, isCamera: boolean): (Vector3, number, Vector3)
    local parsedKey
    local recoil
    local rVec3
    local rmod
    local rcam
    local reset

    -- parse runtime strings (absr)
	parsedKey = self:parseRecoilRuntimeString({}, patternKey)

    -- gather recoil var
    -- this changes the table to Up, Side.
    recoil = Vector3.new(parsedKey[2], parsedKey[1], parsedKey[3])

    rmod = self.weaponVar.vecModifier
    rVec3 = Vector3.new(recoil.X * rmod, recoil.Y * rmod, recoil.Z * rmod)
    rcam, reset = self:updateRecoilVectorTableAsCamera(recoil, parsedKey)

    -- set camera variables
    if isCamera then
        recoil = rcam
        self.weaponVar.lastSavedRecVec = recoil
    else
        -- grab the vec modifier after cam var update incase mod was updated
        recoil = rVec3
    end

    return recoil, rmod, rcam, reset
end

-- apply fire max to fake vector
-- return vector3
function Recoil:fire_applyFVMax(fv, recoil)
    local max = self.weaponVar.options.fireVectorCameraMax
    for i, v  in pairs(fv) do
        local _rec = recoil[i]
        fv[i] = _rec > 0 and math.min(_rec, max[i]) or math.max(_rec, -max[i])
    end
    return Vector3.new(fv.X, fv.Y, fv.Z)
end

return Recoil