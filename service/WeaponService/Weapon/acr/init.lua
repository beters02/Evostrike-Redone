local ACR = {
	Configuration = {
		name = "acr",
		inventorySlot = "primary",
		automatic = true,
		
		equipLength = 0.85,
		fireRate = 0.0952, -- 630 RPM
		reloadLength = 0.85,
		recoilReset = 0.22,
		camRecoilReset = 0.5,
		
		recoilResetMin = 0.25, -- 1st bullet reset
		recoilResetMax = 0.4, -- Based on cameraRecoilReset in sprayPattern
		cameraShakeAmount = 0.22,
		
		fireVectorCameraOffset = Vector2.new(1, 20), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(1.1, 1.4), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.03, 0.05, 0.3), -- Up, Side (0.38 is the 5th bullet's camera vector amount.)
		
		ammo = {
			magazine = 25,
			total = 100
		},
		
		accuracy = {
			firstBullet = 2,
			base = 2,
			crouch = 1.9,
			walk = 130,
			run = 130,
			jump = 150
		},
		
		damage = {
			base = 33,
			min = 28,

			headMultiplier = 4.6,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 0.2,
			damageFalloffDistance = 54,
			damageFalloffMinimumDamage = 28,
			enableHeadFalloff = false,
			helmetMultiplier = 0.88,
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