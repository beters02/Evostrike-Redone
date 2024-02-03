local Config = {
    MaxFramesPerPage = 30,
    DefaultOpeningCaseCFrame = CFrame.new(Vector3.new(0.2, 0.4, 0)) * CFrame.Angles(0, 9.766, 0),
    FinalItemCanvasPosition = Vector2.new(2023, 0)
}

local rotDeg90 = math.pi*-.5
local vector3Rad = function(x, y, z)
    return Vector3.new(math.rad(x), math.rad(y), math.rad(z))
end

return Config