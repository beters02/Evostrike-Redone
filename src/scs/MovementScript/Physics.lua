local GroundCast = require(game:GetService("ReplicatedStorage"):WaitForChild("Scripts"):WaitForChild("Functions"):WaitForChild("GroundCast"))

local module = {}

-- remake the module using Apply instead of Get
-- (apply the changes directly to the player's current velocity instead of adding all the changes up and applying at the end)

--[[
	@title 			- ApplyGroundVelocity
	@summary

	@param
]]

function module:ApplyGroundVelocity()

	-- get acceleration (move) direction
	local accelDir = self:GetAccelerationDirection() -- "wishDir"
	
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
	self:ApplyGroundAcceleration(accelDir, wishSpeed)

end

function module:ApplyFriction(modifier)

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
	local decel = self.groundDeccelerate

	-- apply friction
	control = speed < decel and decel or speed
	drop = control * fric * self.currentDT * modifier

	if type(drop) ~= "number" then
		print(drop)
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

function module:ApplyGroundAcceleration(wishDir, wishSpeed)

	local addSpeed
	local accelerationSpeed
	local currentSpeed
	local currentVelocity = self.movementVelocity.Velocity
	local newVelocity = currentVelocity
	
	-- if no inputs, don't accelerate
	if wishDir.Magnitude == 0 then return end
	
	-- get current/add speed
	currentSpeed = currentVelocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed
	
	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then return end
	
	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.groundAccelerate * self.currentDT * wishSpeed, addSpeed)
	
	-- you can't change the properties of a Vector3, so we do x, y, z
	newVelocity += (accelerationSpeed * wishDir)

	-- clamp magnitude (max speed)
	--newSpeed = newSpeed.Unit * (math.min(newSpeed.Magnitude, self.groundMaxSpeed))

	-- clamp magnitude (max velocity)
	if newVelocity.Magnitude > self.maxVelocity then
		newVelocity = newVelocity.Unit * (math.min(newVelocity.Magnitude, self.maxVelocity))
	end

	-- apply
	self.movementVelocity.Velocity = newVelocity

end

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

function module:GetMovementVelocityForce()
	return Vector3.new(self.movementVelocityForce, 0, self.movementVelocityForce)
end

function module:GetMovementVelocityAirForce()
	local accelDir = self:GetAccelerationDirection()
	return Vector3.new(self.movementVelocityForce*math.abs(accelDir.x), 0, self.movementVelocityForce*math.abs(accelDir.z))
end

function module:GetAccelerationDirection()
	if self.currentInputSum.Forward == 0 and self.currentInputSum.Side == 0 then
		return Vector3.zero
	end
	local side = (self.cameraYaw * CFrame.Angles(0,math.rad(90),0)).lookVector * self.currentInputSum.Side
	local forward = (self.cameraLook * self.currentInputSum.Forward)
	local new = forward + side
	if math.abs(new.Magnitude) > 1 then
		new = new.Unit
	end
	new = Vector3.new(new.X, 0, new.Z)
	return new, forward, side
end

return module
