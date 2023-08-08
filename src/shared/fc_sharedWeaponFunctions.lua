local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Strings = Framework.sc_strings or Framework.__index(Framework, "shfc_strings")

local module = {}

function module.checkSplitForNeg(split)
	for i, v in pairs(split) do
		if string.match(v, "neg") then
			split[i] = "-" .. v:sub(4, v:len())
		end
	end
	return split
end
function module.numberAbsoluteValueCheck(str)
	
end

-- RETURN NUMBERS FROM STRINGS
function module.initStrings(str)--: tuple -- strings to be formatted on require
	--[[
		Range String format:
		"range_EndBulletNumber_StartValue-EndValue"
		
		Smooth Linear Progression from StartValue to EndValue
		Returns a tuple with -> EndBullet, StartValue, EndValue
	]]
	if string.match(str, "range") then
		local split = string.split(str, "_")
		local rangeSplit = string.split(split[3], "-")
		rangeSplit = module.checkSplitForNeg(rangeSplit)
		return tonumber(split[2]), tonumber(rangeSplit[1]), tonumber(rangeSplit[2])
	end

	--[[
		Constant String format:
		"const_EndBulletNumber_Value"
		
		Constant Value starting from current index and going to EndBulletNumber.
		Returns a tuple
	]]
	if string.match(str, "const") then--: EndBullet, Value
		local split = module.checkSplitForNeg(string.split(str, "_"))
		return tonumber(split[2]), tonumber(split[3])
	end
	
	--[[
		Speed String format:
		"speed_StartValue_EndValue_Speed"
		
		Lerp to end value using a set speed
		
		@return: tuple -> startValue, endValue, speed
	]]
	if string.match(str, 'speed') then
		local split = string.split(str, "_")
		return tonumber(split[2], split[3])
	end
end

function module.duringStrings(str): number -- strings to be formatted real time
	if string.match(str, "absr") then -- Absolute Value Random (1, -1)
		local chars = Strings.seperateToChar(string.gsub(str, "absr", ""))

		local numstr = ""
		for i, v in chars do
			if tonumber(v) or tostring(v) == "." then
				numstr = numstr .. v
			end
		end

		return (math.random(0, 1) == 1 and 1 or -1) * tonumber(numstr)
	end
end

return module