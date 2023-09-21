-- [[ FrameworkType: FunctionContainer ]]
--[[


    @summary
    This is a FunctionContainer that is binded to the cameraObject class upon creation.

]]

local Recoil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local sharedWeaponFunctions = require(Framework.shfc_sharedWeaponFunctions.Location)

--[[ MAIN ]]

function Recoil:FireRecoil(currentBullet)

    -- Resolve: Inconsistent Feeling Camera Recoil at Low FPS
    -- Schedule recoil

    -- recoil is already scheduled
    if self.weaponVar._waiting then return end

    -- recoil not scheduled and debounce active
    if self.weaponVar._localDebounce and tick() < self.weaponVar._localDebounce then
        self.weaponVar._waiting = true

        -- schedule recoil here
        repeat task.wait() until tick() >= self.weaponVar._localDebounce

        self.weaponVar._waiting = false
    end

    -- set debounce to active
    self.weaponVar._localDebounce = tick() + (self.weaponVar.options.fireRate - 0.002)

    -- update the classes current bullet
    self.weaponVar.currentBullet = currentBullet

    -- init camera var
    local recoilvec
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
    recoilvec = self:getRecoilVector3(self:getSprayPatternKey(), true)
    recoilvec *= self.weaponVar.camModifier
    recfv = {X = recoilvec.X, Y = recoilvec.Y, Z = recoilvec.Z} -- do this for easy editing
    ui = 2 -- default up iterations
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
    diff = 1
    up = true
    counter = 1

    -- init camera recoil custom lerp
    self.connection = RunService.RenderStepped:Connect(function(dt)
        t = tick()

        -- camera recoil up
        if up then
            -- set lerp time to upspeed --TODO: self.weaponVar.options.cameraUpSpeed or 0.03
            lerpTime = 1/60

            -- if iteration next tick has been reached, then update the pos
            if t >= unxt then

                -- keep track of any massive frame difference, in that case
                -- we will want to "catch" the camera up
                diff = math.max(1, t / unxt)

                -- set next
                unxt = t + lerpTime
                
                -- update count
                if counter == ui then
                    up = false
                    dnxt = t
                end
                counter += 1
            end

            -- set goal rotation (update with dt)
            goalRotation = Vector3.new(rupf.X, rupf.Y, 0) * diff * dt * 60

        elseif not up then

            -- set lerp time to camreset
            lerpTime = self.weaponVar.camReset

            -- down recoil iteration reached
            if t >= dnxt then

                -- diff
                diff = t / dnxt

                -- set next
                dnxt = t + (self.weaponVar.camReset/di)

                -- set down recoil vector based on the total recoiled vector amount which is set in the final update phase
                rdpf = self.weaponVar.totalRecoiledVector/di
                
                -- update count
                if counter == di then
                    stop = true
                end

                counter += 1
            end

            -- set rot
            goalRotation = Vector3.new(-rdpf.X, -rdpf.Y, 0) * dt * 60 * diff
        end
        
        -- final update phase
        -- update camera and set total recoil
        self.camera.CFrame *= CFrame.Angles(goalRotation.X, goalRotation.Y, 0)
        self.weaponVar.totalRecoiledVector += Vector3.new(goalRotation.X, goalRotation.Y, 0)
        
        -- finished?
        if stop then
            self.connection:Disconnect()
        end

        
    end)
end

function Recoil:StopCurrentRecoilThread()
    if self.connection then
        self.connection:Disconnect()
    end
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
    self.weaponVar.camModifier = parsedKey[5] or self.weaponVar.camModifier
    self.weaponVar.camReset = parsedKey[6] or self.weaponVar.camReset
    return Vector3.new(_fv.X, _fv.Y, _fv.Z)
end

-- returns the vector3 to be added to vector recoil
-- the recoil vector table is Up, Side instead of Side, Up
function Recoil:getRecoilVector3(patternKey: table, isCamera: boolean): Vector3
    local parsedKey
    local recoil
    local rVec3
    local rmod
    local rcam

    -- parse runtime strings (absr)
	parsedKey = self:parseRecoilRuntimeString({}, patternKey)

    -- gather recoil var
    -- this changes the table to Up, Side.
    recoil = Vector3.new(parsedKey[2], parsedKey[1], parsedKey[3])

    rmod = self.weaponVar.vecModifier
    rVec3 = Vector3.new(recoil.X * rmod, recoil.Y * rmod, recoil.Z * rmod)
    rcam = self:updateRecoilVectorTableAsCamera(recoil, parsedKey)
    
    -- set camera variables
    if isCamera then
        recoil = rcam
        self.weaponVar.lastSavedRecVec = recoil
    else
        -- grab the vec modifier after cam var update incase mod was updated
        recoil = rVec3
    end

    return recoil, rmod, rcam
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