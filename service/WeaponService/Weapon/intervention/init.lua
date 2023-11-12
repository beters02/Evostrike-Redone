local intervention = {
    Configuration = {
        name = "intervention",
		inventorySlot = "primary",
		automatic = false,
        scope = true,
		
		equipLength = 1,
		fireRate = 1.1,
		reloadLength = 1.1,
		recoilReset = 0.5,
        scopeLength = 0.14,
		
		recoilResetMin = 0.15, -- 1st bullet reset
		recoilResetMax = 0.25, -- Based on cameraRecoilReset in sprayPattern
		
		fireVectorCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.008, 0.007, 0.1), -- Up, Side
		
		ammo = {
			magazine = 3,
			total = 6
		},
		
		accuracy = {
			firstBullet = 1,
            unScopedBase = 15,
			base = 1,
			crouch = 1,
			spray = 2,
			walk = 100,
			run = 100,
			jump = 120,
			spread = true
		},
		
		damage = {
			base = 170,
			min = 150,

			headMultiplier = 7,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 0.5,
			damageFalloffDistance = 25,
			enableHeadFalloff = false,
			headFalloffMultiplier = 0.6, -- Multiplier applied to damage falloff per meter
			helmetMultiplier = 1,
			destroysHelmet = true,
		},

		movement = {
			penalty = -4.4,
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

intervention.Configuration.damage.damageFalloffMinimumDamage = intervention.Configuration.damage.min

local sprayPattern = require(script:WaitForChild("spraypattern"))
intervention.Configuration.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.spread)


return intervention