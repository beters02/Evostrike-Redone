local playerActions = {
    properties = {
        id = "PlayerActions",
        replicated = false,
        clientReadOnly = false,
        owner = "Client"
    },
	defaultVar = {
		shooting = false,
        reloading = false,
        weaponEquipped = false,
        weaponEquipping = false,
        grenadeThrowing = false,
        currentEquipPenalty = 0,
	}
}

return playerActions