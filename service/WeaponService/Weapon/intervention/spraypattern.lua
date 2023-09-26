-- neg = makes a number negative in a string use: "const_endBullet_negConstValue" ex: "const_10_neg1"
-- range = creates a linear range lasting until specified end bullet. use: "range_endBullet_startValue-endValue" ex: "range_10_1-10"
-- const = constant number until specified end bullet. use: "const_endBullet_constValue" ex: "const_10_1"
-- absr = absolute value random use: "numberValueabsr" ex: "1absr" = 1 or -1

-- {side, up, shake}
-- spread = {x, y, z}
-- spread will apply each value by
-- spread[i] * fireDirection[i] * baseAccuracy
local sprayPattern = {
	spread = {{"1absr", 1, "0.4absr"}}
}

--sprayPattern.spread.bulletstart = 2 -- bullet when the spread starts to increase
--sprayPattern.spread.bulletend = 5 -- bullet when the spread reaches it's max

return sprayPattern