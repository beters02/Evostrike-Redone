-- neg = makes a number negative in a string use: "const_endBullet_negConstValue" ex: "const_10_neg1"
-- range = creates a linear range lasting until specified end bullet. use: "range_endBullet_startValue-endValue" ex: "range_10_1-10"
-- const = constant number until specified end bullet. use: "const_endBullet_constValue" ex: "const_10_1"
-- absr = absolute value random use: "numberValueabsr" ex: "1absr" = 1 or -1
-- vec = {x, y, z, modifier, springSpeed, springDamp, returnSpeed, returnDamp}

-- vec current = {[1] = x, [2] = y, [3] = z, [4] = vectorModifier, [5] = camModifier, [6] = cameraRecoilReset}
local sprayPattern = {


	vec =
		{{"0.3absr", 1.33, 0.1, "range_3_0.5-1", 0.27, "range_8_0.27-0.45"}, -- Bullet #1
		{"range_5_0.12-1.55", "range_8_1.05-1.29", 0.3},
		{0, 0, 0.66},
		{0, 0, 0},
		{1, 0, 0},
		{1, 0, 0},
		{"range_14_1.55-neg1.55", 0, 0},
		{0, "const_30_0", 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{-1.55, 0, 0},
		{-1.55, 0, 0},
		{"range_21_neg1.55-1.55", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{1.55, 0, 0},
		{1.55, 0, 0},
		{"range_30_1.55-0", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0}}
}

return sprayPattern