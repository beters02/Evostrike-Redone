local profile = {

	-- case:
		-- a case object will be a string that looks like:
		-- "case_caseName"

		-- a key object will be a string that looks like:
		-- "key_keyName"

	-- skin:
		-- a skin object will be a string that looks like:
		-- "weaponName_skinName"

		-- if it is a skin of a weapon with multiple models:
		-- "weaponName_modelName_skinName

    inventory = {case = {}, skin = {}, equipped = {
		ak47 = "default",
		glock17 = "default",
		knife = "default_default",
		vityaz = "default",
		ak103 = "default",
		usp = "default",
		acr = "default",
		deagle = "default"
	}},

    options = {
        crosshair = {
			red = 0,
			blue = 255,
			green = 255,
			gap = 5,
			size = 5,
			thickness = 2,
			dot = false,
			dynamic = false,
			outline = false
		},

		camera = {
			vmX = 0,
			vmY = 0,
			vmZ = 0,
			FOV = 75,
		},

		keybinds = {
			primaryWeapon = "One",
			secondaryWeapon = "Two",
			ternaryWeapon = "Three",
			primaryAbility = "F",
			secondaryAbility = "V",
			interact = "E",
			jump = "Space",
			crouch = "LeftControl",
			inspect = "T",
			drop = "G",

			aimToggle = 1, -- 1 = toggle, 0 = hold
			crouchToggle = 0
		}
    },

	states = {
		isQueueProcessing = false,
		isQueueAdding = false,
		isQueueRemoving = false,
		isQueueDisabled = false,
		hasBeenGivenAdminInventory = false, -- applied in adminModifications
	},

	economy = {
		strafeCoins = 0,
		premiumCredits = 0
	}
}

return profile