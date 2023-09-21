local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local InitSprayPattern = require(Framework.shfc_initSprayPattern.Location)

local module = {
	inventorySlot = "ternary",
	automatic = true,

	-- model = secondToSkipTo
	inspectAnimationTimeSkip = {
		default = 0.03,
		karambit = 0.225,
		m9bayonet = 0.1
	},

	damageCastLength = 7,
	
	totalAmmoSize = 90,
	magazineSize = 30,
	
	equipLength = 1,
	fireRate = 0.325,
	secondaryFireRate = 0.75,
	reloadLength = 1.5,
	recoilReset = 0.3,
	
	fireVectorCameraOffset = Vector2.new(10, 10),
	fireVectorCameraMax = Vector3.new(0.008, 0.007, 0.1),
	
	fireVectorSpring = {
		speed = 50,
		damp = 1,
		downWait = 0.07,
		max = 0.1
	},
	
	accuracy = {base = 1},
	
	damage = {
		base = 27.5,
		secondary = 50,
		headMultiplier = 1.5,
		primaryBackstab = 75,
		secondaryBackstab = 150,
	},

	movement = {
		penalty = 0,
		hitTagAmount = 6
	}
	
}

module.sprayPattern = "Melee"

return module