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
		local sub = self.airMaxSpeedFrictionDecrease * self.currentDT * 60
		local curr = self.currentAirFriction
		local fric = curr - sub
		if fric < 0 then
			fric = curr + fric
		end

		self:ApplyFriction(math.max(1, fric/self.friction))
		self.currentAirFriction = math.max(0, curr - sub)
	else
		self:ApplyFriction(1)
	end

	-- set the target speed of the player
	local wishSpeed = accelDir.Magnitude
	wishSpeed *= (self.groundMaxSpeed + self.maxSpeedAdd + self.equippedWeaponPenalty)
	
	-- apply acceleration
	self:ApplyGroundAcceleration(accelDir, wishSpeed)

	self:ApplyAntiSticking(self.movementVelocity.Velocity)

	-- calculate slope movement
	local forwardVelocity: Vector3 = groundNormal:Cross(CFrame.Angles(0,math.rad(90),0).LookVector * Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z))
	
	local yVel
	if self.laddering then
		yVel = self.ladderLerpVelocity.Y
		self.collider.Velocity = Vector3.new(self.collider.Velocity.X, yVel, self.collider.Velocity.Z)
	else
		yVel = forwardVelocity.Unit.Y * Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z).Magnitude
	end

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
	
	-- get current/add speed
	currentSpeed = currentVelocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed
	
	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then return end
	
	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.groundAccelerate * self.currentDT * wishSpeed, addSpeed)
	
	-- you can't change the properties of a Vector3, so we do x, y, z
	newVelocity += (accelerationSpeed * wishDir)
	newVelocity = Vector3.new(newVelocity.X, self.sliding and newVelocity.Y or 0, newVelocity.Z)

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
		self:ApplyFriction(0.01 * self.currentAirFriction)
	end
	
	-- apply acceleration
	local accelspeed = self:ApplyAirAcceleration(accelDir, wishSpeed)

	self:ApplyAntiSticking(self.movementVelocity.Velocity, self.dashing, accelspeed)

	-- calculate slope movement
	if self.sliding then
		local forwardVelocity: Vector3 = self.slideNormal:Cross(CFrame.Angles(0,math.rad(90),0).LookVector * Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z))
		local yVel = forwardVelocity.Unit.Y * Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z).Magnitude

		-- apply slope movement
		self.movementVelocity.Velocity = Vector3.new(self.movementVelocity.Velocity.X, yVel * (accelDir.Y < 0 and 1.2 or 1) * self.currentDT * 60, self.movementVelocity.Velocity.Z)
	end
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

	-- get current/add speed
	currentSpeed = self.movementVelocity.Velocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed

	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then return end

	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.airAccelerate * self.currentDT * wishSpeed, addSpeed)

	-- get new velocity
	local newVelocity = self.movementVelocity.Velocity + accelerationSpeed * wishDir

	-- apply acceleration
	self.movementVelocity.Velocity = newVelocity
	
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
	else
		groundNormal = groundNormal or Vector3.new(0,1,0)
		forward = groundNormal:Cross(self.collider.CFrame.RightVector)
		right = groundNormal:Cross(forward)
		accelDir = (forwardMove * forward + rightMove * right).Unit
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