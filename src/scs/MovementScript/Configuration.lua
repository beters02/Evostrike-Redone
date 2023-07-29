local module = {

	--[[ General Settings ]]
	gravity = .23,
	friction = 6,
	maxVelocity = 50,
	maxMovementPitch = 0.6,

	--[[ Ground Settings ]]
	groundAccelerate = 10,
	groundDeccelerate = 8,
	groundMaxSpeed = 18,

	--[[ Air Settings ]]
	airAccelerate = 45,
	airSpeed = 5,
	airMaxSpeed = 31,
	airMaxSpeedFriction = 3.5,

	--[[ Jump Settings ]]
	jumpVelocity = 25,
	jumpTimeBeforeGroundRegister = 0.1,

	--[[ Land Settings ]]
	minInAirTimeRegisterLand = 0.3,
	landingMovementDecrease = 0.8,
	landingMovementDecreaseLength = 0.15,

	--[[ Bhop Settings ]]
	missedBhopDecrease = 0.4,
	autoBunnyHop = false,

	--[[ Character Settings ]]
	playerTorsoToGround = 3.6,
	movementStickDistance = 0.85

}

return module