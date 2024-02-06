local wepconfig = {
	Configuration = {
		name = "hkp30",
		inventorySlot = "secondary",
		automatic = false,
		
		equipLength = 0.65,
		fireRate = 0.16,
		reloadLength = 0.65,
		recoilReset = 0.32,
		
		recoilResetMin = 0.32, -- 1st bullet reset
		recoilResetMax = 0.32, -- Based on cameraRecoilReset in sprayPattern
		
		fireVectorCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(8, 8), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.008, 0.007, 0.1), -- Up, Side
		
		ammo = {
			magazine = 12,
			total = 24
		},
		
		accuracy = {
			firstBullet = 4,
			base = 11.5,
			crouch = 8.5,
			spray = 2,
			walk = 16,
			run = 18,
			jump = 120,
			spread = true
		},
		
		damage = {
			base = 19,
			min = 12,

			headMultiplier = 5.35,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 1.5,
			damageFalloffDistance = 20,
			enableHeadFalloff = false,
			headFalloffMultiplier = 0.6, -- Multiplier applied to damage falloff per meter
			helmetMultiplier = 0.42,
			destroysHelmet = false,
		},

		movement = {
			penalty = -2.2,
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

wepconfig.Configuration.damage.damageFalloffMinimumDamage = wepconfig.Configuration.damage.min

local sprayPattern = require(script:WaitForChild("spraypattern"))
wepconfig.Configuration.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.spread)

return wepconfig