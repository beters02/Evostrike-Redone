local AK103 = {}
AK103.Configuration = {
    name = "ak47",
    inventorySlot = "primary",
	automatic = true,
	
	equipLength = 0.9,
	fireRate = 0.1, -- 600 rpm
	reloadLength = 0.9,
	recoilReset = 0.24, -- DEPRECATEd
	camRecoilReset = 0.5, -- DEPRECATED

	recoilResetMin = 0.25, -- 1st bullet reset
	recoilResetMax = 0.45, -- Based on cameraRecoilReset in sprayPattern
	
	fireVectorCameraOffset = Vector2.new(4, 24), -- Side, Up
	fireAccuracyCameraOffset = Vector2.new(3, 3), -- Side, Up
	fireVectorCameraMax = Vector3.new(0.03, 0.03, 0.3), -- Up, Side (0.38 is the 5th bullet's camera vector amount.)
	--fireVectorCameraMax = Vector3.new(1, 1, 3), -- Up, Side
	
	ammo = {
		magazine = 30,
		total = 90
	},
	
	accuracy = {
		firstBullet = 2,
		base = 5,
		crouch = 4,
		walk = 200,
		run = 200,
		jump = 150
	},
	
	damage = {
		base = 40,
		min = 33,
		
		headMultiplier = 5,
		legMultiplier = 0.9,
		damageFalloffPerMeter = 0.7,
		damageFalloffDistance = 40,
		damageFalloffMinimumDamage = 20,
		enableHeadFalloff = false,
		helmetMultiplier = 1,
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
			speed = 3,		-- 4
			multiplier = 1.8, -- 1
			min = -2,
			max = 2
		}
	},

	equipSpringShoveFunction = function(spr, dt)
		local fshov = Vector3.new(2, 0, 0)*dt*60
		local frame = 1/60 * (dt*60)

		spr:shove(fshov*0.8)
		task.wait(frame*2)
		spr:shove(-fshov*0.8)
	end,
	
	serverModelSize = 0.75
}

local sprayPattern = require(script:WaitForChild("spraypattern"))
AK103.Configuration.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.vec)

return AK103