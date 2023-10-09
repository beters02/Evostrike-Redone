local module = {

	--[[ General Settings ]]
	gravity = .25,
	friction = 7.5,
	maxVelocity = 50,
	maxMovementPitch = 0.6,
	surfSlopeAngle = 0.58,

	--[[Sound Settings]]
	walkNoiseSpeed = 15.5,

	--[[ Ground Settings ]]
	groundAccelerate = 10.2,
	groundDeccelerate = 16, -- the lower this number is, the longer it takes to decel btw
	groundMaxSpeed = 21,

	walkMoveSpeed = 14,
	walkAccelerate = 12,

	crouchMoveSpeed = 10,
	crouchFriction = 6,
	crouchAccelerate = 19,

	--[[ Air Settings ]]
	airAccelerate = 40,
	airSpeed = 6,
	airMaxSpeed = 36, -- 34
	airMaxSpeedFriction = 6,
	airMaxSpeedFrictionDecrease = .5, -- amount of times per 1/60sec to decrease air fric

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

module.defGroundAccelerate = module.groundAccelerate
module.defGroundDeccelerate = module.groundDeccelerate
module.defFriction = module.friction

return module