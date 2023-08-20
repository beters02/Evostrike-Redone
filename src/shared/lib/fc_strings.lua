local Strings = {}

function Strings.firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

function Strings.seperateToChar(str)
	local new = {}
	for i = 1, #str do
		table.insert(new, str:sub(i,i))
	end
	return new
end

return Strings