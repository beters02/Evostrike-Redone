local Math = {}

--round2
-- Round to second decimal
function Math.twoDec(value: number): number
	local new = value
	new *= 100
	new = math.floor(new)
	new = new / 100
	return new
end

--v3min
-- Min all vector3 values
function Math.vector3Min(vec: Vector3, min: number): number
	local new = {X = vec.X, Y = vec.Y, Z = vec.Z}
	for i, v in pairs(new) do
		new[i] = math.min(min, v)
	end
	return Vector3.new(new.X, new.Y, new.Z)
end

--v3max
-- Max all vector3 values
function Math.vector3Max(vec: Vector3, max: number)
	local new = {X = vec.X, Y = vec.Y, Z = vec.Z}
	for i, v in pairs(new) do
		new[i] = math.max(max, v)
	end
	return Vector3.new(new.X, new.Y, new.Z)
end

--absr
-- Randomly multiply by 1 or -1
function Math.absValueRandom(value: number): number
	local r = math.round(math.random(1000,2000)/1000)
	local v = r == 1 and -1 or 1
	print(r, v)
	return value * v
end

-- mmabs
-- Max -m if < 0 or Min m
--[[function Math.maxOrMinAbs(value, m)
	return value > 0 and math.min(value, m) or math.max(value, -m)
end]]

function Math.fixedMin(value, m)
	return value > 0 and math.min(value, m) or math.min(value, -m)
end

function Math.fixedMax(value, m)
	return value > 0 and math.max(value, m) or math.max(value, -m)
end

Math.maxOrMinAbs = Math.fixedMin

-- frand
-- Fixed Random By Abs Value Range
function Math.fixedRandomAbsRange(value)
	return value > 0 and math.random(-value, value) or math.random(value, -value)
end

--v3add
function Math.vector3Add(vector, value)
	local _v = {}
	for i, v in pairs({X = vector.X, Y = vector.Y, Z = vector.Z}) do
		_v[i] = v + value
	end
	return Vector3.new(_v.X, _v.Y, _v.Z)
end

--v3sub
function Math.vector3Sub(vector, value)
	local _v = {}
	for i, v in pairs({X = vector.X, Y = vector.Y, Z = vector.Z}) do
		_v[i] = v - value
	end
	return Vector3.new(_v.X, _v.Y, _v.Z)
end

-- Aliases
Math.absr = Math.absValueRandom
Math.mmabs = Math.maxOrMinAbs
Math.round2 = Math.twoDec
Math.v3max = Math.vector3Max
Math.v3min = Math.vector3Min
Math.frand = Math.fixedRandomAbsRange
Math.v3add = Math.vector3Add
Math.v3sub = Math.vector3Sub

return Math