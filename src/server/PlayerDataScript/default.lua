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
		-- "weaponName_modelName_skinName"

	-- The table index value of the item is it's UUID.
	-- All default skins have a UUID of 0.

    inventory = {case = {}, skin = {}, equipped = {
		ak47 = "default_0",
		glock17 = "default_0",
		knife = "default_default_0",
		vityaz = "default_0",
		ak103 = "default_0",
		usp = "default_0",
		acr = "default_0",
		deagle = "default_0",
		intervention = "default_0",
		hkp30 = "default_0",
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
			equipLastEquippedWeapon = "Q",
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
		hasBeenGivenInventoryReset1 = false,
	},

	economy = {
		strafeCoins = 0,
		premiumCredits = 0
	}
}

return profile