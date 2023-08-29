local profile = {
    inventory = {case = {}, skin = {}},
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
		}
    },
	states = {
		isQueueProcessing = false,
		isQueueAdding = false,
		isQueueRemoving = false,
		isQueueDisabled = false
	}
}

return profile