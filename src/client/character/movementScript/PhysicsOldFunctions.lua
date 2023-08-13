local module = {}

--[[
	GetGroundVelocity

	@return New Velocity Vector3 after all ground movement functions are passed
]]

function module:GetGroundVelocity(prevVelocity)
	
	local newVelocity

	-- get acceleration (move) direction
	local accelDir = self:GetAccelerationDirection() -- "wishDir"
	
	-- ground normal for slopes
	--local groundResult = GroundCast(self.player.Character)
	--local groundNormal = groundResult.Normal

	-- apply friction
	newVelocity = self:ApplyFrictionVector(self.movementVelocity.Velocity, 1)

	-- for slopes ????????
	--local forwardVelocity = groundNormal:Cross(CFrame.new(Vector3.zero):ToAxisAngle(Vector3.new(0, 1, 0), -90) * Vector3.new(prevVelocity.X, 0, prevVelocity.Y))
	
	-- calculate how much slopes should affect movement
	--float yVelocityNew = forwardVelocity.normalized.y * new Vector3 (_surfer.moveData.velocity.x, 0f, _surfer.moveData.velocity.z).magnitude;

	-- set the target speed of the player
	local wishSpeed = accelDir.Magnitude
	wishSpeed *= self.groundMaxSpeed
	
	-- accelerate
	newVelocity = self:GroundAccelerateVector(newVelocity, accelDir, wishSpeed)

	-- clamp magnitude (max velocity)
	if newVelocity.Magnitude > self.maxVelocity then
		newVelocity = newVelocity.Unit * (math.min(newVelocity.Magnitude, self.maxVelocity))
	end
	
	return newVelocity
end

function module:GetAirVelocity(prevVelocity)
	
	local newVelocity

	-- get move direction
	local accelDir = self:GetAccelerationDirection()

	-- get wanted speed
	local wishSpeed = accelDir.Magnitude
	wishSpeed *= self.airSpeed

	-- apply friction if max speed is reached
	local currSpeed = prevVelocity.Magnitude
	if currSpeed > self.airMaxSpeed then
		prevVelocity = self:ApplyFrictionVector(prevVelocity, self.airMaxSpeedFriction)
		print('max speed reached')
	end
	
	-- accelerate
	newVelocity = self:AirAccelerateVector(prevVelocity, accelDir, wishSpeed)
	
	return newVelocity
end

--[[
	AccelerateVector

	@return New Velocity Vector3 after Acceleration
]]
function module:GroundAccelerateVector(prevVelocity, wishDir, wishSpeed)
	
	local addSpeed
	local accelerationSpeed
	local currentSpeed
	local dt
	local x
	local y
	local z
	local newSpeed
	
	-- if no inputs, don't accelerate
	if wishDir.Magnitude == 0 then return prevVelocity end
	
	-- get current/add speed
	dt = self.currentDT
	currentSpeed = prevVelocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed
	
	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then return prevVelocity end
	
	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.groundAccelerate * dt * wishSpeed, addSpeed)
	
	-- you can't change the properties of a Vector3, so we do x, y, z
	x = prevVelocity.X + accelerationSpeed * wishDir.X
	y = 0
	z = prevVelocity.Z + accelerationSpeed * wishDir.Z
	newSpeed = Vector3.new(x, y, z)

	-- clamp magnitude (max speed)
	--newSpeed = newSpeed.Unit * (math.min(newSpeed.Magnitude, self.groundMaxSpeed))

	return newSpeed
end

function module:AirAccelerateVector(prevVelocity, wishDir, wishSpeed)
	
	local addSpeed
	local accelerationSpeed
	local currentSpeed
	local dt
	local newSpeed

	-- if no inputs, don't accelerate
	if wishDir.Magnitude == 0 then return prevVelocity end

	-- get current/add speed
	dt = self.currentDT
	currentSpeed = prevVelocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed

	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then return prevVelocity end

	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.airAccelerate * dt * wishSpeed, addSpeed)

	-- apply acceleration
	newSpeed = prevVelocity + accelerationSpeed * wishDir

	return newSpeed
end

--[[
	@title ApplyFriction
	@summary
					- Apply friction to a given Velocity.

	@param			- {Vector3} prevVelocity 	- Velocity to be edited

	@param[opt]		- {number} mod 				- Friction modifier
					- default: 1

	@param[opt]		- {number} iterations 		- Total loop iterations
					- default: 12
	
	@return			- {Vector3} newVelocity		- Edited Velocity
]]
function module:ApplyFrictionVector(prevVelocity, mod)

	local vel = prevVelocity
	local speed = vel.Magnitude
	
	-- if we're not moving, don't apply friction
	if speed <= 0 then
		return prevVelocity
	end

	local drop = 0
	local control
	local newSpeed
	local newVel

	local fric = self.friction
	local accel = self.groundAccelerate
	local decel = self.groundDeccelerate

	local x = vel.X
	local y = vel.Y
	local z = vel.Z

	-- apply friction only when grounded
	y = vel.Y
	control = speed < decel and decel or speed
	drop = control * fric * self.currentDT * mod

	--????????????
	newSpeed = math.max(speed - drop, 0)
	if speed > 0 and newSpeed > 0 then
		newSpeed /= speed
	end

	return Vector3.new(x * newSpeed, y * newSpeed, z * newSpeed)
end

--[[
	IsSticking
	
	@return sticking : bool or table - Detects what direction player is sticking in
]]

--local VisualizeSticking = false

--[[function module:IsSticking()
	local character = self.character
	local camera = self.camera

	local stickParams = RaycastParams.new()
	stickParams.FilterType = Enum.RaycastFilterType.Exclude
	stickParams.FilterDescendantsInstances = {character, camera, workspace.Temp}
	
	local rayOffset = Vector3.new(0, -.9, 0)
	local hrpCF = character.HumanoidRootPart.CFrame
	local hrpPos = hrpCF.Position
	local rayPos = hrpPos + rayOffset

	local offsetMod = 1.05
	local midOffsetMod = 1.75

	local forwardValues = {hrpCF.LookVector, -hrpCF.LookVector}
	local sideValues = {-hrpCF.RightVector, hrpCF.RightVector}
	local sticking = false
	
	local forSidVal = {forwardValues[1], forwardValues[2], sideValues[1], sideValues[2]}
	local dir
	local stickNorm

	-- 8 direction sticking
	for i, v in pairs(forSidVal) do
		local fResults = {{v * offsetMod, workspace:Raycast(rayPos, v, stickParams)}}

		if i < 3 then
			local middleLeft = sideValues[1] and (v + sideValues[1])/2 or false
			local middleRight = sideValues[2] and (v + sideValues[2])/2 or false
			if middleLeft then
				table.insert(fResults, {middleRight * midOffsetMod, workspace:Raycast(rayPos, middleRight * midOffsetMod, stickParams)})
			end
			if middleRight then
				table.insert(fResults, {middleLeft * midOffsetMod, workspace:Raycast(rayPos, middleLeft * midOffsetMod, stickParams)})
			end
		end

		for a, b in pairs(fResults) do
			if b[2] then
				visualizeRayResult(b[2], rayPos)
				if not sticking then sticking = true end
				dir = b[1]
				stickNorm = b[2].Normal
				--return b[1], b[2].Normal
			else
				visualizeRayResult(false, rayPos, b[1])
			end
		end

	end

	if sticking then
		return dir, stickNorm
	end

	return false
end]]

--[[
	@title 			- Movement.Land (Old)
	@summary
					- Produces a movement decrease for a specified time and decrease amount.
					- Doesn't stop at goal, only stops after time is reached. 

	@param[opt]		- {number} decrease - Amount goal to decrease current movement speed by.
					- default: Movement.landingMovementDecrease

	@param[opt]		- {number} waitTime - Total length of speed decrease.
					- default: Movement.landingMovementDecreaseLength

	@param[opt]		- {number} iterations - Total loop iterations
					- default: 12
	
	@return			- {void}
]]
--[[function Movement.OldLand(decrease, waitTime, iterations)
	--print('landed')
	--TODO: play land sound
	local landsnd = Movement.Sounds.landDefault
	local runsnd = Movement.Sounds.runDefault
	runsnd.Volume = 0
	if landsnd.IsPlaying then landsnd:Stop() end
	landsnd:Play()
	task.delay(0.1, function()
		landsnd:Stop()
		runsnd.Volume = runv
	end)

	decrease = decrease or Movement.landingMovementDecrease
	waitTime = waitTime or Movement.landingMovementDecreaseLength
	iterations = iterations or 12
	landing = true

	local currentVelocity = Movement.movementVelocity.Velocity
	local currentSpeed = currentVelocity.Magnitude
	local goal
	local sub
	local frictionApplied = false

	-- avoid / 0 errors
	if currentSpeed <= 0 then
		landing = false
		return
 	end

	-- get the goal speed
	local goal = Movement.movementVelocity.Velocity.Magnitude * Movement.landingMovementDecrease

	-- get the total amount of speed to subtract per iteration
	local sub = iterations / goal

	-- get the total amount to wait per iteration
	waitTime = Movement.landingMovementDecreaseLength / iterations

	-- iterate
	for i = iterations, 1, -1 do
		--print('iteration ' .. tostring(i))

		local newVelocity = Movement.movementVelocity.Velocity

		-- when the player jumps, we want to cancel the land delay so they can hit bhops
		if jumping or inAir then
			--print("jump cancel")
			break
		end

		-- if theres no movement input, we only want to apply friction
		if Movement.currentInputSum.Forward == 0 and Movement.currentInputSum.Side == 0 then
			if not frictionApplied then
				frictionApplied = true
				Movement:ApplyFriction(1)
			end
			task.wait(waitTime)
			continue
		elseif frictionApplied then
			frictionApplied = false
		end
		
		-- if sub < 1 then we DONT want to divide, we multiply by the decimal instead
		local s = sub < 1 and (sub * i)/iterations or (sub/i)/iterations

		-- for the first two frames, only slow by a quarter to allow bhops
		if i > iterations - 3 then
			s += (s * .25)
		end
		
		-- set new velocity variable
		newVelocity *= s

		-- if newVelocity is lower than what we want, we set the minimum to goal
		if newVelocity.Magnitude < goal then
			newVelocity = newVelocity.Unit * math.max(newVelocity.Magnitude, goal)
		end

		-- apply velocity
		Movement.movementVelocity.Velocity = newVelocity
		
		-- break on land end
		if i == 1 then
			--print('land delay finished')
			break
		end

		task.wait(waitTime)
	end

	landing = false
end]]

return module