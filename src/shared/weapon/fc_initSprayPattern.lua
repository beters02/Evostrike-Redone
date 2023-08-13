local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Math = require(Framework.shfc_math.Location)
local weaponFireCustomString = require(Framework.shfc_sharedWeaponFunctions.Location)

local module = {}

-- REAL TIME FORMAT FUNCTIONS

function module.formatRangeString(startBulletNumber, bulletTableIndex, stringValue, sprayPattern)
	local endBulletNumber, startValue, endValue = weaponFireCustomString.initStrings(stringValue)
	local add = Math.twoDec((endValue - startValue)/(endBulletNumber-startBulletNumber))
	local last = startValue
	for currentBulletNumber = startBulletNumber, endBulletNumber do
		local new
		if currentBulletNumber == startBulletNumber then
			new = startValue
		elseif currentBulletNumber == endBulletNumber then
			new = endValue
		else
			new = last + add
		end
		last = new
		sprayPattern[currentBulletNumber][bulletTableIndex] = new
	end
	return sprayPattern
end

function module.formatConstantString(startBulletNumber, bulletTableIndex, stringValue, sprayPattern)
	local endBulletNumber, endValue = weaponFireCustomString.initStrings(stringValue)
	for currentBulletNumber = startBulletNumber, endBulletNumber do
		sprayPattern[currentBulletNumber][bulletTableIndex] = endValue
	end
	return sprayPattern
end

function module.formatSpeedString(startBulletNumber, bulletTableIndex, stringValue, sprayPattern)
	local startValue, endValue, speed = weaponFireCustomString.initStrings(stringValue)
	local endBulletNumber = math.round(startValue/endValue * speed)
end

function module.formatStrings(bulletNumber, bulletTable, sprayPattern)
	for propertyIndex, propertyValue in pairs(bulletTable) do
		if type(propertyValue) == "string" then
			if string.match(propertyValue, "range") then
				sprayPattern = module.formatRangeString(bulletNumber, propertyIndex, propertyValue, sprayPattern)
			elseif string.match(propertyValue, "const") then
				sprayPattern = module.formatConstantString(bulletNumber, propertyIndex, propertyValue, sprayPattern)
			end
		end
	end
	return sprayPattern
end

-- "INIT" FORMAT FUNCTIONS

return function(sprayPattern)
	
	local storedRange = {}
	local storedConst = {}

	-- Main Formatting
	for bulletNumber, bulletTable in pairs(sprayPattern) do
		sprayPattern = module.formatStrings(bulletNumber, bulletTable, sprayPattern)
	end
	
	return sprayPattern
end