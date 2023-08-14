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

	local newVel = vel
	local newSpeed
	local drop = 0
	local control
	
	local fric = self.friction
	local accel = self.groundAccelerate
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

function module:ApplyGroundVelocity(groundNormal)

	-- update accel dir for sticking
	self:GetAccelerationDirection()

	-- test
	local forward = groundNormal:Cross(self.collider.CFrame.RightVector)
	local right = groundNormal:Cross(forward)
	local forwardMove = self.currentInputSum.Forward
    local rightMove = self.currentInputSum.Side
    local accelDir = (forwardMove * forward + rightMove * right).Unit

	if self.currentInputSum.Forward == 0 and self.currentInputSum.Side == 0 then accelDir = Vector3.zero end

	-- apply friction
	self:ApplyFriction(1)

	-- set the target speed of the player
	local wishSpeed = accelDir.Magnitude
	wishSpeed *= (self.groundMaxSpeed + self.maxSpeedAdd)
	
	-- apply acceleration
	self:ApplyGroundAcceleration(accelDir, wishSpeed)

end

--[[
	Slope Ground Velocity
	-- get acceleration (move) direction
	local accelDir, wallHit = self:GetAccelerationDirection() -- "wishDir"
	
	-- ground normal for slopes
	--local groundResult = GroundCast(self.player.Character)
	--local groundNormal = groundResult.Normal

	-- apply friction
	--newVelocity = self:ApplyFrictionVector(self.movementVelocity.Velocity, 1)
	self:ApplyFriction(1)

	-- set the target speed of the player
	local wishSpeed = accelDir.Magnitude
	wishSpeed *= self.groundMaxSpeed

	-- for slopes ????????
	--local forwardVelocity = groundNormal:Cross(CFrame.new(Vector3.zero):ToAxisAngle(Vector3.new(0, 1, 0), -90) * Vector3.new(prevVelocity.X, 0, prevVelocity.Y))
	
	-- calculate how much slopes should affect movement
	--float yVelocityNew = forwardVelocity.normalized.y * new Vector3 (_surfer.moveData.velocity.x, 0f, _surfer.moveData.velocity.z).magnitude;
	
	-- apply acceleration
	self:ApplyGroundAcceleration(accelDir, wishSpeed, wallHit)
]]


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
	local wallHit
	
	-- if no inputs, don't accelerate
	if wishDir.Magnitude == 0 then
		if self.dashing then
			wishDir = self.collider.CFrame.LookVector
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
	newVelocity = Vector3.new(newVelocity.X, 0, newVelocity.Z)

	-- detect if player is against wall
	newVelocity, wallHit = self:ApplyAntiSticking(newVelocity)

	-- clamp magnitude (max speed)
	if newVelocity.Magnitude > (self.groundMaxSpeed + self.maxSpeedAdd) and not self.dashing then
		newVelocity = newVelocity.Unit * math.min(newVelocity.Magnitude, (self.groundMaxSpeed + self.maxSpeedAdd))
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
	local wallHit

	-- get move direction
	accelDir = self:GetAccelerationDirection()

	-- get wanted speed
	wishSpeed = accelDir.Magnitude
	wishSpeed *= self.airSpeed

	-- set air friction if max speed is reached
	currSpeed = vel.Magnitude
	if currSpeed > (self.airMaxSpeed + (self.maxSpeedAdd * 0.8)) and not self.dashing then
		self.currentAirFriction = self.airMaxSpeedFriction
	end

	-- friction
	if self.currentAirFriction > 0 then
		self:ApplyFriction((self.currentAirFriction/self.friction) * self.currentDT * 60)
		self.currentAirFriction -= (self.airMaxSpeedFrictionDecrease * self.currentDT * 60)
	end
	
	-- apply acceleration
	self:ApplyAirAcceleration(accelDir, wishSpeed)
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
	local newSpeed
	local wallHit

	-- if no inputs, don't accelerate
	if wishDir.Magnitude == 0 then
		if not self.dashing then
			self.movementVelocity.Velocity = self:ApplyAntiSticking(self.movementVelocity.Velocity)
			return
		end
		wishDir = self.collider.CFrame.LookVector
	end

	-- get current/add speed
	currentSpeed = self.movementVelocity.Velocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed

	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then
		self.movementVelocity.Velocity = self:ApplyAntiSticking(self.movementVelocity.Velocity)
		return
	end

	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.airAccelerate * self.currentDT * wishSpeed, addSpeed)

	-- get new velocity
	local newVelocity = self.movementVelocity.Velocity + accelerationSpeed * wishDir

	-- if a wall was hit, dont accelerate in that direction
	newVelocity, wallHit = self:ApplyAntiSticking(newVelocity)
	--newVelocity = self:ApplyWallHit(wallHit, newVelocity, wishDir)

	-- apply acceleration
	self.movementVelocity.Velocity = newVelocity

end

--[[
	@title 			- GetAccelerationDirection
	@summary

	@return wishDir: Wished direction of player
]]

function module:GetAccelerationDirection()
	local wishDir
	local inputVec
	local wallHit

	-- if no input, direction = 0, 0, 0
	if self.currentInputSum.Forward == 0 and self.currentInputSum.Side == 0 then
		return Vector3.zero
	end

	-- get forward and side inputs
	inputVec = Vector3.new(-self.currentInputSum.Side, 0, -self.currentInputSum.Forward).Unit
	self.currentInputVec = inputVec

	-- convert vector into worldspace
	wishDir = self.player.Character.PrimaryPart.CFrame:VectorToWorldSpace(inputVec)
	return wishDir
end

function module:GetMovementVelocityForce()
	return Vector3.new(self.movementVelocityForce, 0, self.movementVelocityForce)
end

function module:GetMovementVelocityAirForce()
	local accelDir = self:GetAccelerationDirection()
	return Vector3.new(self.movementVelocityForce*math.abs(accelDir.x), 0, self.movementVelocityForce*math.abs(accelDir.z))
end

return module
