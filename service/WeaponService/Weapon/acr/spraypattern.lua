-- neg = makes a number negative in a string use: "const_endBullet_negConstValue" ex: "const_10_neg1"
-- range = creates a linear range lasting until specified end bullet. use: "range_endBullet_startValue-endValue" ex: "range_10_1-10"
-- const = constant number until specified end bullet. use: "const_endBullet_constValue" ex: "const_10_1"
-- absr = absolute value random use: "numberValueabsr" ex: "1absr" = 1 or -1
-- vec = {x, y, z, modifier, springSpeed, springDamp, returnSpeed, returnDamp}

-- vec current = {[1] = Side, [2] = Up, [3] = Shake, [4] = vectorModifier, [5] = camModifier, [6] = cameraRecoilReset}

local sprayPattern = {
	vec = {
		{"0.15absr", 1.4, 0.1, 0, 0.38, .25}, -- Bullet #1
		{"0.15absr", "range_8_1-1.1", 0.3, "range_7_0.23-0.94", false, 0.29},
		{"0.15absr", 0, 0.66, 0.3, false, 0.4},
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
		{0, 0, 0}
	}
}

--[[local sprayPattern = {
	vec =
		{{"0.3absr", 1.33, 0.1, "range_6_0-1", 0.415, "range_8_0.25-0.41"}, -- Bullet #1
		{.12, "range_8_1.05-1.28", 0.3},
		{.24, 0, 0.66},
		{"range_8_0.66-neg1.2", 0, 0},
		{1, 0, 0},
		{1, 0, 0},
		{0, 0, 0},
		{0, "const_30_0", 0},
		{"range_14_neg1.25-1.6", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{1.55, 0, 0},
		{1.55, 0, 0},
		{"range_21_1.6-neg1.56", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{-1.55, 0, 0},
		{-1.55, 0, 0},
		{"range_30_neg1.6-0", 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0}}
}]]

return sprayPattern