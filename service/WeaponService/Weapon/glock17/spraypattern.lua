-- neg = makes a number negative in a string use: "const_endBullet_negConstValue" ex: "const_10_neg1"
-- range = creates a linear range lasting until specified end bullet. use: "range_endBullet_startValue-endValue" ex: "range_10_1-10"
-- const = constant number until specified end bullet. use: "const_endBullet_constValue" ex: "const_10_1"
-- absr = absolute value random use: "numberValueabsr" ex: "1absr" = 1 or -1

-- spread = {x, y, z}
-- spread will apply each value by
-- spread[i] * fireDirection[i] * baseAccuracy
-- vec current = {[1] = x, [2] = y, [3] = z, [4] = vectorModifier, [5] = camModifier, [6] = cameraRecoilReset}
local sprayPattern = {
	spread = {{"range_4_0-1", "range_4_0.5-1", "0.4absr", "range_4_0-0.7", 0.33, 0.35}, -- Bullet #1
		{0, 0, 0, "0.4absr"},
		{0, 0, "0.4absr"},
		{0, 0, 0},
		{"const_15_1.5", "const_15_1.5", 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
	}
}

return sprayPattern