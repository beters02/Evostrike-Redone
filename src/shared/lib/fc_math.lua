local Math = {}

function Math.twoDec(value: number): number
	local new = value
	new *= 100
	new = math.floor(new)
	new = new / 100
	return new
end

function Math.vector3Min(vec: Vector3, min: number): number
	local new = {X = vec.X, Y = vec.Y, Z = vec.Z}
	for i, v in pairs(new) do
		new[i] = math.min(min, v)
	end
	return Vector3.new(new.X, new.Y, new.Z)
end

function Math.vector3Max(vec: Vector3, max: number)
	local new = {X = vec.X, Y = vec.Y, Z = vec.Z}
	for i, v in pairs(new) do
		new[i] = math.max(max, v)
	end
	return Vector3.new(new.X, new.Y, new.Z)
end

function Math.absValueRandom(value: number): number
	return value * math.random(0,1) == 0 and -1 or 1
end

return Math