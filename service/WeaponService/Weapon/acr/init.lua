local ACR = {
	Configuration = {
		name = "acr",
		inventorySlot = "primary",
		automatic = true,
		
		equipLength = 0.85,
		fireRate = 0.086, -- 700 rpm
		reloadLength = 0.85,
		recoilReset = 0.22,
		camRecoilReset = 0.5,
		
		recoilResetMin = 0.25, -- 1st bullet reset
		recoilResetMax = 0.41, -- Based on cameraRecoilReset in sprayPattern
		
		fireVectorCameraOffset = Vector2.new(2, 20), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(3.8, 3.8), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.03, 0.07, 0.3), -- Up, Side (0.38 is the 5th bullet's camera vector amount.)

		--[[fireVectorCameraOffset = Vector2.new(5, 13), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(1, 10), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.009, 0.0101, 0.3), -- Up, Side]]
		
		ammo = {
			magazine = 25,
			total = 100
		},
		
		accuracy = {
			firstBullet = 2,
			base = 4,
			crouch = 10,
			walk = 190,
			run = 190,
			jump = 150
		},
		
		damage = {
			base = 36,
			min = 33,

			headMultiplier = 4,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 0.7,
			damageFalloffDistance = 35,
			damageFalloffMinimumDamage = 19,
			enableHeadFalloff = false,
			helmetMultiplier = 0.78,
			destroysHelmet = true,
		},
		
		movement = {
			penalty = -2.6,
			hitTagAmount = 6
		},

		fireSpring = {
			pos = {
				mass = 5,		-- 5
				force = 50,		-- 50
				damping = 4,	-- 4
				speed = 3,		-- 4
				multiplier = 0.2, -- 1
				min = Vector3.new(0, -1.1, -1.1),
				max = Vector3.new(0, 1.1, 1.1)
			},
			rotUp = {
				mass = 5,		-- 5
				force = 50,		-- 50
				damping = 4,	-- 4
				speed = 1,		-- 4
				multiplier = 1, -- 1
				min = -1.1,
				max = 1.1
			},
			rotSide = {
				mass = 5,		-- 5
				force = 50,		-- 50
				damping = 4,	-- 4
				speed = 4,		-- 4
				multiplier = 1.8, -- 1
				min = -2,
				max = 2
			}
		},

		serverModelSize = 0.75
	}
}

local sprayPattern = require(script:WaitForChild("spraypattern"))
ACR.Configuration.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.vec)

return ACR