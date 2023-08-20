


-- neg = makes a number negative in a string use: "const_endBullet_negConstValue" ex: "const_10_neg1"
-- range = creates a linear range lasting until specified end bullet. use: "range_endBullet_startValue-endValue" ex: "range_10_1-10"
-- const = constant number until specified end bullet. use: "const_endBullet_constValue" ex: "const_10_1"
-- absr = absolute value random use: "numberValueabsr" ex: "1absr" = 1 or -1
-- shake = {x, y, z, modifier, springSpeed, springDamp}
-- vec = {x, y, z, modifier, springSpeed, springDamp, returnSpeed, returnDamp}

-- vec current = {[1] = x, [2] = y, [3] = z, [4] = vectorModifier, [5] = camModifier, [6] = cameraRecoilReset}
local sprayPattern = {
	vec = {{"0.03absr", 0.04, 0.1, 0.1, 0.25, 0.03}, -- Bullet #1
		{"range_5_0.12-1", 0.2, 0.3, 0.3, false, 0.2},
		{0, 0.4, 0.66, "range_7_0.6-1"},
		{0, "range_7_0.7-2.2", "const_7_1.1"},
		{0, 0, 0},
		{1, 0, 0},
		{1, 0, 0},
		{"range_14_1.3-neg1.3", "const_30_0", 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{-1.37, 0, 0},
		{-1.33, 0, 0},
		{"range_21_neg1.3-1.3", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{"range_30_1-0", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0}},
	shake = {{"1absr", "const_30_2", "0.7absr", 0.55}, -- Bullet #1
		{"1.5absr", 0, "0.7absr"},
		{"range_7_1.5-2", 0, "0.7absr"},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{"range_14_neg1-neg2", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{"range_25_1-2", 0, 0},
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
		{"range_30_neg1-neg1.5", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0}}
}

return sprayPattern