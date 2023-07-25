local module = {
	playerTorsoToGround = 3.1,
	movementStickDistance = .1,

	airAccelerate = 16,
	airSpeed = 6,
	airMaxSpeed = 31,
	airMaxSpeedFriction = 3.5,

	groundAccelerate = 10,
	groundDeccelerate = 8,
	groundMaxSpeed = 18,
	
	jumpVelocity = 42,
	jumpTimeBeforeGroundRegister = 0.1,

	minInAirTimeRegisterLand = 0.5,
	landingMovementDecrease = 0.5,
	landingMovementDecreaseLength = 0.2,

	missedBhopDecrease = 0.6,

	gravity = .25,
	friction = 6,
	maxVelocity = 50,

	autoBunnyHop = false,

	maxMovementPitch = 0.6,
}

return module
