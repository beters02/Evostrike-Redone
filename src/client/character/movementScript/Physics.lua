local module = {}

--[[
	@title ApplyFriction
	@summary
					- Apply friction to the player's velocity.


	@param[opt]		- {number} modifier 				- Friction modifier
					- default: 1

	
	@return			- {void}
]]

function module:ApplyFriction(modifier, decel)

	local vel = self.movementVelocity.Velocity
	local speed = vel.Magnitude
	
	-- if we're not moving, don't apply friction
	if speed <= 0 then
		return vel
	end

	local newSpeed
	local drop = 0
	local control
	
	local fric = self.friction
	decel = decel or self.groundDeccelerate

	-- apply friction
	control = speed < decel and decel or speed
	drop = control * fric * self.currentDT * modifier

	if type(drop) ~= "number" then
		drop = drop.Magnitude
	end

	-- ????????????
	newSpeed = math.max(speed - drop, 0)
	if speed > 0 and newSpeed > 0 then
		newSpeed /= speed
	end

	-- apply
	self.movementVelocity.Velocity = vel * newSpeed
end

--[[
	@title 			- ApplyGroundVelocity
	@summary

	@param
]]

function module:ApplyGroundVelocity(groundNormal: Vector3)

	-- update accel dir for sticking
	local accelDir = self:GetAccelerationDirection(groundNormal)

	-- friction
	if self.currentAirFriction > 0 then
		self:ApplyFriction((math.max(self.airMaxSpeedFrictionDecrease-self.currentAirFriction, self.currentAirFriction) * .75/self.friction) * self.currentDT * 60)
		self.currentAirFriction -= (self.airMaxSpeedFrictionDecrease * self.currentDT * 60)
	else
		self:ApplyFriction(1)
	end

	-- set the target speed of the player
	local wishSpeed = accelDir.Magnitude
	wishSpeed *= (self.groundMaxSpeed + self.maxSpeedAdd + self.equippedWeaponPenalty)
	
	-- apply acceleration
	self:ApplyGroundAcceleration(accelDir, wishSpeed)

	-- calculate slope movement
	local forwardVelocity: Vector3 = groundNormal:Cross(CFrame.Angles(0,math.rad(90),0).LookVector * Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z))
	local yVel = forwardVelocity.Unit.Y * Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z).Magnitude

	-- apply slope movement
	self.movementVelocity.Velocity = Vector3.new(self.movementVelocity.Velocity.X, yVel * (accelDir.Y < 0 and 1.2 or 1), self.movementVelocity.Velocity.Z)

end

--[[
	@title 			- ApplyGroundAcceleration
	@summary

	@param
]]

function module:ApplyGroundAcceleration(wishDir, wishSpeed)

	local addSpeed
	local accelerationSpeed
	local currentSpeed
	local currentVelocity = self.movementVelocity.Velocity
	local newVelocity = currentVelocity
	
	-- if no inputs, don't accelerate
	if wishDir.Magnitude == 0 then
		if self.dashing then
			self.movementVelocity.Velocity = self:ApplyAntiSticking(currentVelocity)
			return
		end
		self.movementVelocity.Velocity = self:ApplyAntiSticking(currentVelocity)
	end
	
	-- get current/add speed
	currentSpeed = currentVelocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed
	
	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then return end

	-- if a wall was hit, dont accelerate in that direction
	--ewVelocity = self:ApplyWallHit(wallHit, newVelocity, wishDir)
	
	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.groundAccelerate * self.currentDT * wishSpeed, addSpeed)
	
	-- you can't change the properties of a Vector3, so we do x, y, z
	newVelocity += (accelerationSpeed * wishDir)
	newVelocity = Vector3.new(newVelocity.X, self.sliding and newVelocity.Y or 0, newVelocity.Z)

	-- detect if player is against wall
	newVelocity = self:ApplyAntiSticking(newVelocity)

	-- clamp magnitude (max speed)
	if newVelocity.Magnitude > (self.groundMaxSpeed + self.maxSpeedAdd + self.equippedWeaponPenalty) and not self.dashing then
		newVelocity = newVelocity.Unit * math.min(newVelocity.Magnitude, (self.groundMaxSpeed + self.maxSpeedAdd + self.equippedWeaponPenalty))
	end

	-- apply acceleration
	self.movementVelocity.Velocity = newVelocity

end

--[[
	@title 			- ApplyAirVelocity
	@summary

	@param
]]

function module:ApplyAirVelocity()
	local accelDir
	local wishSpeed
	local currSpeed
	local vel = self.movementVelocity.Velocity

	-- get move direction
	accelDir = self:GetAccelerationDirection()

	-- get wanted speed
	wishSpeed = accelDir.Magnitude
	wishSpeed *= self.airSpeed

	-- set air friction if max speed is reached
	currSpeed = vel.Magnitude
	if currSpeed > (self.airMaxSpeed + (self.maxSpeedAdd + self.equippedWeaponPenalty * 0.8)) and not self.dashing then
		self.currentAirFriction = self.airMaxSpeedFriction
	end

	-- continue air friction friction
	if self.currentAirFriction > 0 then
		self:ApplyFriction(0.01 * self.currentAirFriction * self.currentDT * 60)
	end
	
	-- apply acceleration
	local accelspeed = self:ApplyAirAcceleration(accelDir, wishSpeed)
	self:ApplyAntiSticking(self.movementVelocity.Velocity, self.dashing, accelspeed)
end

--[[
	@title 			- ApplyAirAcceleration
	@summary

	@param
]]

function module:ApplyAirAcceleration(wishDir, wishSpeed)

	local currentSpeed
	local addSpeed
	local accelerationSpeed
	
	-- apply anti sticking on collider velocity
	-- resolves head collision ** THIS IS A MUST HAVE **
	--self.collider.Velocity = self:ApplyAntiSticking(self.collider.Velocity, true, wishSpeed - self.collider.Velocity.Magnitude)
	
	-- if no inputs, don't accelerate
	if wishDir.Magnitude == 0 then
		if self.dashing then
			wishDir = self.collider.Velocity.Unit * wishSpeed
		else
			--self.movementVelocity.Velocity = self:ApplyAntiSticking(self.movementVelocity.Velocity, true, wishSpeed - self.movementVelocity.Velocity.Magnitude)
			return wishSpeed - self.movementVelocity.Velocity.Magnitude
		end
	end

	-- get current/add speed
	currentSpeed = self.movementVelocity.Velocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed

	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then
		return addSpeed
	end

	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.airAccelerate * self.currentDT * wishSpeed, addSpeed)

	-- get new velocity
	local newVelocity = self.movementVelocity.Velocity + accelerationSpeed * wishDir

	-- if a wall was hit, dont accelerate in that direction
	--newVelocity = self:ApplyAntiSticking(newVelocity, self.dashing, addSpeed)

	-- apply acceleration
	self.movementVelocity.Velocity = newVelocity

	--[[if self.dashing then
		task.wait()
	end]]
	
	return addSpeed
end

--[[
	@title 			- GetAccelerationDirection
	@summary

	@return wishDir: Wished direction of player
]]

-- THIS IS IT!!!!!
-- THANK YOU SEROEQUEL !
-- -Bryce @ 3am when he found the yaw->direction script after his seroquel had kicked in
--[[function getYaw(): CFrame
	return workspace.CurrentCamera.CFrame*CFrame.Angles(-getPitch(),0,0)
end]]
function getYaw()
	return workspace.CurrentCamera.CFrame*CFrame.Angles(-(math.pi/2 - math.acos(workspace.CurrentCamera.CFrame.LookVector:Dot(Vector3.new(0,1,0)))),0,0)
end

function module:GetAccelerationDirection(groundNormal)

	if self.currentInputSum.Forward == 0 and self.currentInputSum.Side == 0 then -- if no input, direction = 0, 0, 0
		self.currentInputVec = Vector3.zero
		if self.dashing then
			self.currentInputSum.Forward = 1
		end
	else
		self.currentInputVec = Vector3.new(-self.currentInputSum.Side, 0, -self.currentInputSum.Forward).Unit -- get forward and side inputs
	end
	

	local forward
	local right
	local accelDir
	local forwardMove = self.currentInputSum.Forward
    local rightMove = self.currentInputSum.Side

	if not self.dashing and self.currentInputSum.Forward == 0 and self.currentInputSum.Side == 0 then
		accelDir = Vector3.zero
	elseif groundNormal then
		forward = groundNormal:Cross(self.collider.CFrame.RightVector)
		right = groundNormal:Cross(forward)
		accelDir = (forwardMove * forward + rightMove * right).Unit
	else
		forward = workspace.CurrentCamera.CFrame.LookVector * self.currentInputSum.Forward
		right = (getYaw() * CFrame.Angles(0,math.rad(90),0)).LookVector * self.currentInputSum.Side
		accelDir = (forward+right).Unit
	end

	return accelDir
end

--

function module:GetMovementVelocityForce()
	return Vector3.new(self.movementVelocityForce, 0, self.movementVelocityForce)
end

function module:GetMovementVelocityAirForce()
	local accelDir = self:GetAccelerationDirection()
	return Vector3.new(self.movementVelocityForce*math.abs(accelDir.x), 0, self.movementVelocityForce*math.abs(accelDir.z))
end

return module