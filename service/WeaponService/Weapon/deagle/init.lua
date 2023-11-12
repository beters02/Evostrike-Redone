local wepconfig = {
	Configuration = {
		name = "deagle",
		inventorySlot = "secondary",
		automatic = false,
		
		equipLength = 0.7,
		fireRate = 0.16, -- 375 rpm
		reloadLength = 0.7,
		recoilReset = 0.57,
		
		recoilResetMin = 0.57, -- 1st bullet reset
		recoilResetMax = 0.57, -- Based on cameraRecoilReset in sprayPattern
		
		fireVectorCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.008, 0.007, 0.1), -- Up, Side
		
		ammo = {
			magazine = 7,
			total = 21
		},
		
		accuracy = {
			firstBullet = 5,
			base = 50,
			crouch = 40,
			spray = 2,
			walk = 170,
			run = 170,
			jump = 150,
			spread = true
		},
		
		damage = {
			base = 55,
			min = 33,

			headMultiplier = 3.3,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 1,
			damageFalloffDistance = 24,
			enableHeadFalloff = false,
			headFalloffMultiplier = 0.6, -- Multiplier applied to damage falloff per meter
			
			helmetMultiplier = 1,
			destroysHelmet = true,
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