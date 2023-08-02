local Recoil = {
    
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Libraries = ReplicatedStorage:WaitForChild("Scripts"):WaitForChild("Libraries")
local WeaponFireCustomString = require(Libraries.WeaponFireCustomString)

-- [[ GET ]]

function Recoil:GetSprayPatternKey()
	return self.weaponVar.options.sprayPattern[self.weaponVar.currentBullet], self.weaponVar.options.shakePattern[self.weaponVar.currentBullet]
end

function Recoil:GetRecoilVector3(patternKey, isCamera: boolean)
    local last = self.weaponVar.lastSavedRecVec
	local new = {}
	for i, v in pairs(patternKey) do
		if type(v) == "string" then
			new[i] = WeaponFireCustomString.duringStrings(v)
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
        print(self.weaponVar.camReset)
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
	local y = recoilVec.Y > 0 and math.min(recoilVec.Y, max.Y) or math.max(recoilVec.Y, -max.Y)
	local z = recoilVec.Z > 0 and math.min(recoilVec.Z, max.Z) or math.max(recoilVec.Z, -max.Z)
    
    recoilVec = Vector3.new(x, y, z)
        
    local ruf = recoilVec * 1/2 -- Recoil Up Vector Amount/Frame
    local rdf = -recoilVec * 1/12

    -- stop currently running fire thread if one exists
    self:StopRecoil()

    -- start camera recoil
    self.thread = task.spawn(function()

        -- up
        --
        --[[for i = 1, 2 do
            self.camera.CFrame *= CFrame.Angles(ruf.X, ruf.Y, ruf.Z)
            task.wait(0.03)
        end

        -- down
        for i = 1, 16 do
            self.camera.CFrame *= CFrame.Angles(rdf.X, rdf.Y, ruf.Z)
            task.wait(self.weaponVar.camReset/16)
        end]]

        -- second variation w/ springs (not fps replicated yet unfortunately)
        --[[self.connection = RunService.RenderStepped:Connect(function(dt)
            if self.recoiling then return end
            local p = self.testSpring.p * dt * 60
            if p.Magnitude == 0 then return end
            self.camera.CFrame *= CFrame.Angles(p.X, p.Y, p.Z)
        end)

        local xShake = math.random(1, 2) <= 1.5 and 0.02 or -0.02
        self.testSpring:Accelerate(0, xShake, 0)
        for i = 1, 2 do
            if self.weaponVar.breakSwitch then return end
            self.recoiling = true
            self.camera.CFrame *= CFrame.Angles(ruf.X, ruf.Y, 0)
            self.recoiling = false
			self.weaponVar.totalRecoiledVec += Vector3.new(ruf.X, ruf.Y, 0)
			task.wait(0.03)
		end

		local recDown = self.weaponVar.totalRecoiledVec/12

        self.testSpring:Accelerate(0, -xShake, 0)
		for i = 1, 12 do
            local s = tick()
            print("start " .. s)
            if self.weaponVar.breakSwitch then return end
            --self.camera.CFrame *= CFrame.Angles(-recDown.X, -recDown.Y, 0)
			--self.weaponVar.totalRecoiledVec += Vector3.new(-recDown.X, -recDown.Y, 0)
            self.recoiling = true
            self.camera.CFrame *= CFrame.Angles(-recDown.X, -recDown.Y, 0)
            self.recoiling = false
			self.weaponVar.totalRecoiledVec += Vector3.new(-recDown.X, -recDown.Y, 0)
			task.wait(self.weaponVar.camReset/12)
            print("end " .. tick() - s)
		end]]

        --6th variation goal CFrame

        local goalRotation = Vector3.new()
        local goalCFrame = false
        
        local nextUpTick = tick()
        local nextDownTick
        local counter = 1
        local up = true
        local ignore = false

        local tr
        local rv

        -- test spring connection
        if self.connection then
            self.connection:Disconnect()
            task.wait()
        end

        self.connection = RunService.RenderStepped:Connect(function(dt)
            local t = tick()
            local stop = false
            local lerpTime = 0.03
            local diff

            if up and not ignore then
                lerpTime = 0.03
                if t >= nextUpTick then
                    --nextUpTick = tick() + 0.03
                    diff = t / nextUpTick
                    nextUpTick = (t) + (0.03)

                    print(counter)

                    if counter == 1 then
                        --goalRotation = CFrame.Angles(ruf.X, ruf.Y, 0)
                        self.testSpring:Accelerate(Vector3.new(0, 0.02, 0))
                        goalRotation = Vector3.new(ruf.X, ruf.Y, 0) * diff * dt * 60
                        counter += 1
                    else
                        goalRotation = Vector3.new(ruf.X, ruf.Y, 0) * diff * dt * 60
                        counter = 1
                        up = false
                        nextDownTick = tick()
                    end
                end
            elseif not up and not ignore then
                lerpTime = self.weaponVar.camReset
                if t >= nextDownTick then
                    diff = t / nextDownTick
                    print(diff)
                    nextDownTick = (t) + (self.weaponVar.camReset/12)
                    --local tr = self.weaponVar.totalRecoiledVector/12

                    tr = self.weaponVar.totalRecoiledVector/12

                    if counter == 1 then
                        --rv = Vector3.new(rdf.X, rdf.Y, 0) * diff
                        self.testSpring:Accelerate(Vector3.new(0, -0.02, 0))
                        rv = Vector3.new(-tr.X, -tr.Y, 0) * dt * 60 * diff
                    else
                        if counter == 12 then
                            stop = true
                            --tr = self.weaponVar.totalRecoiledVector
                        end
                        print(tr)
                        rv = Vector3.new(-tr.X, -tr.Y, 0) * dt * 60 * diff
                        --goalRotation = Vector3.new(rdf.X, rdf.Y, 0) * counter * diff
                    end

                    goalRotation = rv
                    print(counter)
                    counter += 1
                end
            end
            
            local newRotation = goalRotation
            local sp = self.testSpring.p * dt * 60
            goalCFrame = self.camera.CFrame * CFrame.Angles(newRotation.X, newRotation.Y, 0) * CFrame.Angles(sp.X, sp.Y, 0)
            self.camera.CFrame = goalCFrame
            self.weaponVar.totalRecoiledVector += Vector3.new(goalRotation.X, goalRotation.Y, 0)
            
            if stop then
                self.connection:Disconnect()
             end
        end)

        --self.downRecoiling = false

        -- up
        --

        --[[for i = 1, 2 do
            if self.weaponVar.breakSwitch then return end
            --totalRecoiledValue += ruf
            goalRotation = CFrame.Angles(ruf.X, ruf.Y, 0)
            print(self.object.Value)
            task.wait(0.03)
        end

        --local downVec = totalRecoiledValue/12
        self.downRecoiling = true
        
        -- down
        for i = 1, 12 do
            if self.weaponVar.breakSwitch then return end
            goalRotation = CFrame.Angles(rdf.X, rdf.Y, 0)
            task.wait(self.weaponVar.camReset/12)
        end]]

        print('thread finished')
        
    end)
end

function Recoil:StopRecoil()

    -- stop currently running fire thread if one exists
    local thread = self.thread
    if thread then
        self.weaponVar.breakSwitch = true
        task.wait()
        self.thread = nil
        self.weaponVar.breakSwitch = false
        task.wait()
    end
    
end

return Recoil