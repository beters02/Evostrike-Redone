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

--sv3min
function Math.specificVector3Min(vec: Vector3, minVec: Vector3)
	local new = {X = vec.X, Y = vec.Y, Z = vec.Z}
	local min = {X = minVec.X, Y = minVec.Y, Z = minVec.Z}
	for i, v in pairs(min) do
		new[i] = math.min(new[i], v)
	end
	return new
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

--v3abs
-- Abs all vector3 values
function Math.vector3Abs(vec: Vector3)
	local new = {X = vec.X, Y = vec.Y, Z = vec.Z}
	for i, v in pairs(new) do
		new[i] = math.abs(v)
	end
	return Vector3.new(new.X, new.Y, new.Z)
end

--sv3max
function Math.specificVector3Max(vec: Vector3, maxVec: Vector3)
	local new = {X = vec.X, Y = vec.Y, Z = vec.Z}
	local min = {X = maxVec.X, Y = maxVec.Y, Z = maxVec.Z}
	for i, v in pairs(min) do
		new[i] = math.max(new[i], v)
	end
	return new
end

--v3clamp
-- Clamp all vector3 values
function Math.vector3Clamp(vec: Vector3, min: number, max: number)
	local new = {X = vec.X, Y = vec.Y, Z = vec.Z}
	for i, v in pairs(new) do
		new[i] = math.clamp(v, min, max)
	end
	return Vector3.new(new.X, new.Y, new.Z)
end

--fv3clamp
function Math.fixedVector3Clamp(vec: Vector3, min: number, max: number)
	local new = {X = vec.X, Y = vec.Y, Z = vec.Z}
	for i, v in pairs(new) do
		new[i] = Math.fixedClamp(v, min, max)
	end
	return Vector3.new(new.X, new.Y, new.Z)
end

--sv3clamp
-- not a good way to do this.
function Math.specificVector3Clamp(vec: Vector3, minVec: Vector3, maxVec: Vector3)
	vec = Math.specificVector3Min(vec, minVec)
	vec = Math.specificVector3Max(vec, maxVec)
	return vec
end

--absr
-- Randomly multiply by 1 or -1
function Math.absValueRandom(value: number): number
	local r = math.round(math.random(1000,2000)/1000)
	local v = r == 1 and -1 or 1
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

function Math.fixedClamp(value, min, max)
	return value > 0 and math.clamp(value, min, max) or math.clamp(value, -max, -min)
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

-- norm2face - by @ DalekAndrew99 on devforums
function Math.normalToFace(normalVector, part)
	local TOLERANCE_VALUE = 1 - 0.001
    local allFaceNormalIds = {
        Enum.NormalId.Front,
        Enum.NormalId.Back,
        Enum.NormalId.Bottom,
        Enum.NormalId.Top,
        Enum.NormalId.Left,
        Enum.NormalId.Right
    }    

    for _, normalId in pairs( allFaceNormalIds ) do
        -- If the two vectors are almost parallel,
        if Math.faceToNormal(part, normalId):Dot(normalVector) > TOLERANCE_VALUE then
            return normalId -- We found it!
        end
    end
    
    return nil -- None found within tolerance.
end

-- face2norm - by @ DalekAndrew99 on devforums
function Math.faceToNormal(part, normalId)
    return part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(normalId))
end

--@creator ClosetRaccoon
function Math.isPrime(n)
	if n%2 == 0 then
        return n == 2
    end

    for i = 3,n^.5,2 do
        if n%i <= 0 then
            return false
        end
    end
    return true
end

function Math.scaleToOffsetNumber(x: number?, y: number?): Vector2
	local viewportSize = workspace.CurrentCamera.ViewportSize
	x = (x or 0) * viewportSize.X
	y = (y or 0) * viewportSize.Y
	return Vector2.new(x,y)
end

function Math.offsetToScaleNumber(x: number?, y: number?): Vector2
	local viewportSize = workspace.Camera.ViewportSize
	
	if not x then
		x = 0
	else
		x /= viewportSize.X
	end

	if not y then
		y = 0
	else
		y /= viewportSize.Y
	end

	return Vector2.new(x, y)
end

function Math.scaleToOffsetUdim(ud: UDim2)
	return UDim2.new(
		Math.scaleToOffsetNumber(ud.X.Scale),
		Math.scaleToOffsetNumber(ud.X.Offset),
		Math.scaleToOffsetNumber(ud.Y.Scale),
		Math.scaleToOffsetNumber(ud.Y.Offset)
	)
end

function Math.rotDeg90()
	return math.pi*-.5
end

function Math.secToMin(sec)
	if sec < 60 then
		return tostring(sec)
	elseif sec == 60 then
		return "1:00"
	end
	local _sec = sec % 60
    if _sec < 10 then
        _sec = "0"..tostring(_sec)
    end
	return tostring(math.floor(sec/60)) .. ": " .. tostring(_sec)
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
Math.norm2face = Math.normalToFace
Math.face2norm = Math.faceToNormal
Math.v3clamp = Math.vector3Clamp
Math.fv3clamp = Math.fixedVector3Clamp
Math.sv3clamp = Math.specificVector3Clamp
Math.sv3max = Math.specificVector3Max
Math.sv3min = Math.specificVector3Min

return Math