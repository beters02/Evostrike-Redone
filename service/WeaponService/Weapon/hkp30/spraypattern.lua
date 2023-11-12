-- neg = makes a number negative in a string use: "const_endBullet_negConstValue" ex: "const_10_neg1"
-- range = creates a linear range lasting until specified end bullet. use: "range_endBullet_startValue-endValue" ex: "range_10_1-10"
-- const = constant number until specified end bullet. use: "const_endBullet_constValue" ex: "const_10_1"
-- absr = absolute value random use: "numberValueabsr" ex: "1absr" = 1 or -1

-- spread = {x, y, z}
-- spread will apply each value by
-- spread[i] * fireDirection[i] * baseAccuracy
local sprayPattern = {
	spread = {{"range_5_0-1", "range_5_0.5-1", "0.4absr", "range_6_0-1", 0.32, "range_8_0.15-0.25"}, -- Bullet #1
		{0, 0, 0, "0.4absr"},
		{0, 0, "0.4absr"},
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0},
		{"const_30_1", "const_30_1.5", 0},
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
		{0, 0, 0},
		{0, 0, 0},
		{0, 0, 0}
	}
}

return sprayPattern