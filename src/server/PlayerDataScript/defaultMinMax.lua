local profile = {
    options = {
        crosshair = {
			red = {min = 0, max = 255},
			blue = {min = 0, max = 255},
			green = {min = 0, max = 255},
			gap = {min = -10, max = 10},
			size = {min = -10, max = 10},
			thickness = {min = -10, max = 10},
		},
		camera = {
			vmX = {min = -3, max = 3},
			vmY = {min = -3, max = 3},
			vmZ = {min = -3, max = 3},
			FOV = {min = 55, max = 90},
		}
    }
}

return profile