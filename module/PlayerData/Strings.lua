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

local fullNumberToNumber = {
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
	Zero = "0"
}

function Strings.convertFullNumberStringToNumberString(str: string)
	return fullNumberToNumber[str] or str
end
Strings.convertFullNumberToNumb = Strings.convertFullNumberStringToNumberString

function Strings.convertNumberStringToFull(str: string)
	for i, v in pairs(fullNumberToNumber) do
		if v == str then
			return i
		end
	end
	return false
end

--[[
	@title ConvertPathToInstance

	@summary Convert a PathString ("ReplicatedStorage.Temp") to it's location's instance/table value

	@param str: string = PathString
	@param start: ...? = StartingLocation or game

	@return value: any = location instance/table
]]

function Strings.convertPathToInstance(str: string, start: any, ignoreError: boolean?)
	local segments = str:split(".")
	local current = start or game

	local success, err = pcall(function()
		for i,v in pairs(segments) do
			current=current[v]
		end
	end)

	if not success then
		return ignoreError and "nil" or error(err)
	end

	--return success(current)
	return current
end

--[[
	@title ConvertPathToInstance

	@summary Do something to the found instance/value from PathString

	@param str: string = PathString
	@param callback: function = Action you would like to do

	@return value: any = returned function value
]]

function Strings.doActionViaPath(path: string, start: any, callback: (...any) -> (...any))
	local segments = path:split(".")
	local current = start or game

	local success, err = pcall(function()
		for i,v in pairs(segments) do

			-- this will return the location the entire Path prefix except the last segment
			-- we will do what we need to do to the table in callback by current[segments[#segments]] = ...
			if i == #segments then
				return callback(current, segments[#segments], segments)
			end

			current = current[v]
		end
	end)
	
	if err then return error(err) end
	return success
end

return Strings