local Config = {
    MaxFramesPerPage = 30
}

local rotDeg90 = math.pi*-.5
local vector3Rad = function(x, y, z)
    return Vector3.new(math.rad(x), math.rad(y), math.rad(z))
end

Config.enum = {
}

return Config