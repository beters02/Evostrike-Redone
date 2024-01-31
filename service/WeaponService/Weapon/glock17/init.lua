local wepconfig = {
	Configuration = {
		name = "glock17",
		inventorySlot = "secondary",
		automatic = false,
		
		equipLength = 0.6,
		fireRate = 0.15,
		reloadLength = 0.6,
		recoilReset = 0.35,

		recoilResetMin = 0.35, -- 1st bullet reset
		recoilResetMax = 0.35, -- Based on cameraRecoilReset in sprayPattern
		
		fireVectorCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.008, 0.007, 0.1), -- Up, Side
		
		ammo = {
			magazine = 15,
			total = 60
		},
		
		accuracy = {
			firstBullet = 5,
			base = 28,
			crouch = 22,
			spray = 2,
			walk = 22,
			run = 25,
			jump = 120,
			spread = true
		},
		
		damage = {
			base = 16,
			min = 10,

			headMultiplier = 6.35,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 1.5,
			damageFalloffDistance = 20,
			enableHeadFalloff = true,
			headFalloffMultiplier = 1, -- Multiplier applied to damage falloff per meter
			helmetMultiplier = 0.8,
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
				multiplier = 0.15, -- 1
				min = Vector3.new(0, -0.65, -0.65),
				max = Vector3.new(0, 0.65, 0.65)
			},
			rotUp = {
				mass = 5,		-- 5
				force = 50,		-- 50
				damping = 4,	-- 4
				speed = 1,		-- 4
				multiplier = 1, -- 1
				min = -.65,
				max = .65
			},
			rotSide = {
				mass = 5,		-- 5
				force = 50,		-- 50
				damping = 4,	-- 4
				speed = 3,		-- 4
				multiplier = 1.8, -- 1
				min = -1,
				max = 1
			}
		},

		serverModelSize = 0.75
	}
}

wepconfig.Configuration.damage.damageFalloffMinimumDamage = wepconfig.Configuration.damage.min

local sprayPattern = require(script:WaitForChild("spraypattern"))
wepconfig.Configuration.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.spread)

return wepconfig