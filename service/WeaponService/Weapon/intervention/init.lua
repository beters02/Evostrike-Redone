local intervention = {
    Configuration = {
        name = "intervention",
		inventorySlot = "primary",
		automatic = false,
        scope = true,
		
		equipLength = 1.5,
		fireRate = 1.2,
		reloadLength = 1.5,
		recoilReset = 0.5,
        scopeLength = 0.2,
		
		fireVectorCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.12, 0.11, 0.1), -- Up, Side
		
		ammo = {
			magazine = 3,
			total = 6
		},
		
		accuracy = {
			firstBullet = 1,
            unScopedBase = 25,
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

		serverModelSize = 0.75
    }
}

intervention.Configuration.damage.damageFalloffMinimumDamage = intervention.Configuration.damage.min

local sprayPattern = require(script:WaitForChild("spraypattern"))
intervention.Configuration.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.spread)


return intervention