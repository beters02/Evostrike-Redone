local module = {

	--[[ General Settings ]]
	gravity = .25,
	friction = 7.5,
	maxVelocity = 50,
	maxMovementPitch = 0.6,

	--[[ Ground Settings ]]
	groundAccelerate = 10.2,
	groundDeccelerate = 16, -- the lower this number is, the longer it takes to decel btw
	groundMaxSpeed = 21,

	walkMoveSpeed = 14,
	--walkFriction

	crouchMoveSpeed = 10,
	crouchFriction = 6,
	crouchDeccelerate = 4,
	crouchAccelerate = 16,

	defGroundAccelerate = 10.2,
	defGroundDeccelerate = 16,
	defFriction = 7.5,

	--[[ Air Settings ]]
	airAccelerate = 22,
	airSpeed = 5,
	airMaxSpeed = 33, -- 33 was the sweet spot but i was hitting hops as much, 35 was too easy to hit hops
	airMaxSpeedFriction = 4,
	airMaxSpeedFrictionDecrease = 1,

	--[[ Jump Settings ]]
	jumpVelocity = 29,
	jumpTimeBeforeGroundRegister = 0.1,

	--[[ Land Settings ]]
	minInAirTimeRegisterLand = 0.1,
	landingMovementDecreaseLength = 0.27,
	landingMovementDecreaseFriction = 0.77,

	--[[ Bhop Settings ]]
	missedBhopDecrease = 0.4,
	autoBunnyHop = false,

	--[[ Character Settings ]]
	playerTorsoToGround = 4.65,
	movementStickDistance = 0.8,
	crouchDownAmount = 1.6,
	defaultCameraHeight = -0.5,

}

return module