local wepconfig = {
	Configuration = {
		name = "vityaz",
		inventorySlot = "primary",
		automatic = true,
		
		equipLength = 0.8,
		fireRate = 0.115, -- 0.118
		reloadLength = 0.8,
		recoilReset = 0.45,

		recoilResetMin = 0.27, -- 1st bullet reset
		recoilResetMax = 0.45, -- Based on cameraRecoilReset in sprayPattern
		
		fireVectorCameraOffset = Vector2.new(2, 20), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(4, 4), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.03, 0.07, 0.3), -- Up, Side (0.38 is the 5th bullet's camera vector amount.)
		
		ammo = {
			magazine = 25,
			total = 100
		},
		
		accuracy = {
			firstBullet = 4,
			base = 6,
			crouch = 5.5,
			walk = 97,
			run = 100,
			jump = 150,
		},
		
		damage = {
			base = 26,
			min = 22,

			headMultiplier = 4,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 0.7,
			damageFalloffDistance = 50,
			damageFalloffMinimumDamage = 20,
			enableHeadFalloff = false,
			helmetMultiplier = 0.7,
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
wepconfig.Configuration.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.vec)

return wepconfig