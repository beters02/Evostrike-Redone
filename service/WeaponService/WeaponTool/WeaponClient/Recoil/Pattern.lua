local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(Framework.Module.lib.fc_strings)
local Math = require(Framework.Module.lib.fc_math)

local Pattern = {
    Parsed = {}
}

function Pattern.ParseSprayPattern(options: table)
    if options.vectorLeavesCrosshairBullet and not options.sprayPattern.parsedVLCB then
        options.sprayPattern.parsedVLCB = true

        -- change the first bullet vectorModifier to 0
        options.sprayPattern[1][4] = 0

        -- set the second bullet's vectorModifier
        -- to a range that ends at specified bullet
        local bullet = options.vectorLeavesCrosshairBullet
        local step = Math.twoDec(2/bullet)
        options.sprayPattern[2][4] = "range_"..tostring(bullet).."_"..tostring(step).."-1"
    end

    Pattern.Parsed = {}
    for i, v in pairs(options.sprayPattern) do
        if not tonumber(i) then
            continue
        end

        Pattern.Parsed[i] = parseBulletKey(v)
    end
end

function Pattern.GetKey(bullet: number)
    return Pattern.Parsed[bullet]
end

--

local function parseBulletKeyString(str: string)
    if string.match(str, "absr") then -- Absolute Value Random (1, -1)
        local chars = Strings.seperateToChar(string.gsub(str, "absr", ""))

        local numstr = ""
        for _, v in chars do
            if tonumber(v) or tostring(v) == "." then
                numstr = numstr .. v
            end
        end

        return Math.absValueRandom(tonumber(numstr))
    end
end

function parseBulletKey(tbl: table)
    local new = {}
    for i, v in pairs(tbl) do
		if type(v) == "string" then
			new[i] = parseBulletKeyString(v)
		else
			new[i] = v
		end
	end
    return new
end

return Pattern