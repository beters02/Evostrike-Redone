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

local sharedWeaponFunctions = (Framework.fc_sharedWeaponFunctions or Framework.__index("Framework", "shfc_sharedWeaponFunctions")).Module


-- [[ GET ]]

function Recoil:GetSprayPatternKey()
	return self.weaponVar.options.sprayPattern[self.weaponVar.currentBullet], self.weaponVar.options.shakePattern[self.weaponVar.currentBullet]
end

function Recoil:GetRecoilVector3(patternKey, isCamera: boolean)
    local last = self.weaponVar.lastSavedRecVec
	local new = {}
	for i, v in pairs(patternKey) do
		if type(v) == "string" then
			new[i] = sharedWeaponFunctions.duringStrings(v)
		else
			new[i] = v
		end
	end

	local recoil = {X = new[2], Y = new[1], Z = new[3]}
    if isCamera then
        for i, v in pairs(recoil) do
            if v == 0 then recoil[i] = last[i] end
        end

        self.weaponVar.vecModifier = new[4] or self.weaponVar.vecModifier
	    self.weaponVar.camModifier= new[5] or self.weaponVar.camModifier
	    self.weaponVar.camReset = new[6] or self.weaponVar.camReset
    end

    local new = Vector3.new(recoil.X * self.weaponVar.vecModifier, recoil.Y * self.weaponVar.vecModifier, recoil.Z * self.weaponVar.vecModifier)
    if isCamera then self.weaponVar.lastSavedRecVec = new end

	return new
end

--[[ MAIN ]]

function Recoil:FireRecoil(currentBullet)

    -- initialize fire variables
    self.weaponVar.currentBullet = currentBullet
	local vec = self:GetSprayPatternKey() -- vec will be sprayPattern.vec or sprayPattern.spread
	local recoilVec = self:GetRecoilVector3(vec, true)
	local max = self.weaponVar.options.fireVectorCameraMax
	recoilVec = (recoilVec/1) * self.weaponVar.camModifier -- /4

	local x = recoilVec.X > 0 and math.min(recoilVec.X, max.X) or math.max(recoilVec.X, -max.X)
    if self.weaponVar.isSpread then x = math.min(math.abs(recoilVec.X), max.X) end
	local y = recoilVec.Y > 0 and math.min(recoilVec.Y, max.Y) or math.max(recoilVec.Y, -max.Y)
	local z = recoilVec.Z > 0 and math.min(recoilVec.Z, max.Z) or math.max(recoilVec.Z, -max.Z)
    
    recoilVec = Vector3.new(x, y, z)
        
    local ruf = recoilVec * 1/2 -- Recoil Up Vector Amount/Frame
    local rdf = -recoilVec * 1/12

    -- stop currently running fire thread if one exists
    self:StopRecoil()

    -- start camera recoil
    local nextUpTick = tick()
    local nextDownTick
    local counter = 1
    local up = true
    local ignore = false
    local camReset = self.weaponVar.camReset

    local tr
    local rv

    local diff = 1

    self.connection = RunService.RenderStepped:Connect(function(dt)
        local t = tick()
        local stop = false
        local lerpTime = 0.03

        if up and not ignore then
            lerpTime = 0.03
            if t >= nextUpTick then
                diff = t / nextUpTick
                nextUpTick = (t) + (0.03)
                --print(counter)

                if counter == 1 then
                    --self.testSpring:Accelerate(Vector3.new(0, 0.02, 0))
                    counter += 1
                else
                    counter = 1
                    up = false
                    nextDownTick = tick()
                end
            end
            goalRotation = Vector3.new(ruf.X, ruf.Y, 0) * diff * dt * 60
        elseif not up and not ignore then
            lerpTime = self.weaponVar.camReset
            if t >= nextDownTick then
                diff = t / nextDownTick
                nextDownTick = (t) + (camReset/12)
                tr = self.weaponVar.totalRecoiledVector/12

                if counter == 1 then
                    --self.testSpring:Accelerate(Vector3.new(0, -0.02, 0))
                else
                    if counter == 12 then
                        stop = true
                    end
                end
                counter += 1
            end
            goalRotation = Vector3.new(-tr.X, -tr.Y, 0) * dt * 60 * diff
        end
        
        local sp = self.testSpring.p * dt * 60
        self.camera.CFrame *= CFrame.Angles(goalRotation.X, goalRotation.Y, 0)
        self.weaponVar.totalRecoiledVector += Vector3.new(goalRotation.X, goalRotation.Y, 0)
        
        if stop then
            self.connection:Disconnect()
         end
    end)

end

function Recoil:StopRecoil()

    -- stop currently running fire thread if one exists
    if self.connection then
        self.connection:Disconnect()
    end
    
end

return Recoil