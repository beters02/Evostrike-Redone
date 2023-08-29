local Strings = {}

function Strings.firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

function Strings.seperateToChar(str)
	local new = {}
	for i = 1, str:len() do
		table.insert(new, str:sub(i,i))
	end
	return new
end

function Strings.charArrayToString(charArray)
	local str = ""
	for i, v in pairs(charArray) do
		str = str .. tostring(v)
	end
	return str
end

function Strings.seperateToNumbers(str)
	local _char = Strings.seperateToChar(str)
	for i, v in pairs(_char) do
		if not tonumber(v) then
			_char[i] = nil
		end
	end
	return Strings.charArrayToString(_char)
end

function Strings.getParsedStringContents(str: string)
	local chars = Strings.seperateToChar(str)
	local currnum = 1
	local ret = {numbers = {""}, action = nil}
	
	for i, v in chars do

		-- if we have a "." or a number, then we are still making the number
		if tonumber(v) or tostring(v) == "." then
			ret.numbers[currnum] = ret.numbers[currnum] .. v

		-- if we have a "-" or a "_", then we are moving on to the next number
		elseif tostring(v) == "-" or tostring(v) == "_" then
			currnum += 1
			ret.numbers[currnum] = ""

		-- if we have only a character, then this is the action.
		else
			ret.action = str:sub(i, str:len())
			break
		end
	end

	return ret
end

return Strings