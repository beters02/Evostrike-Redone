-- neg = makes a number negative in a string use: "const_endBullet_negConstValue" ex: "const_10_neg1"
-- range = creates a linear range lasting until specified end bullet. use: "range_endBullet_startValue-endValue" ex: "range_10_1-10"
-- const = constant number until specified end bullet. use: "const_endBullet_constValue" ex: "const_10_1"
-- absr = absolute value random use: "numberValueabsr" ex: "1absr" = 1 or -1
-- vec = {x, y, z, modifier, springSpeed, springDamp, returnSpeed, returnDamp}

-- vec current = {[1] = Side, [2] = Up, [3] = Shake, [4] = vectorModifier, [5] = camModifier, [6] = cameraRecoilReset}
local sprayPattern = {
	vec =
		{{0, 1.4, 0.1, 0, 0.43, .25}, -- Bullet #1
		{0, "range_8_1-1.1", 0.3, "range_9_0.23-1", false, 0.35},
		{0, 0, 0.66, 0.3, false, 0.45},
		{0, 0, 0},
		{0, 0, 0},
		{1, 0, 0},
		{1, 0, 0},
		{"range_13_1.39-neg1.393", 0, 0},
		{0, 1.15, 0},
		{0, 1.2, 0},
		{0, 1.25, 0},
		{0, "range_15_1.25-1", 0},
		{-1.393, 0, 0},
		{-1.393, 0, 0},
		{-1.393, 0, 0},
		{"range_21_neg1.393-1.393", "const_30_0", 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{1.393, 0, 0},
		{1.393, 0, 0},
		{"range_30_1.393-0", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0}}
}

-- Previous

return sprayPattern