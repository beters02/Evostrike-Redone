local Config = {
    MaxFramesPerPage = 30
}

local rotDeg90 = math.pi*-.5
local vector3Rad = function(x, y, z)
    return Vector3.new(math.rad(x), math.rad(y), math.rad(z))
end

Config.enum = {
    CustomWeaponPositions = {
        Get = function(invSkin)
            local par = false
            if invSkin.weapon == "knife" then
                par = Config.enum.CustomWeaponPositions.knife[invSkin.model]
            else
                par = Config.enum.CustomWeaponPositions[invSkin.weapon]
            end
            return par
        end,
        
        default = {vec = Vector3.new(0.5,0,-3)},

        knife = {
            vec = Vector3.new(1, 0, -3),
            --rot = Vector3.new(0, math.rad(rotDeg90), 0),
            karambit = {vec = Vector3.new(-0.026, -0.189, -1.399)},
            default = {vec = Vector3.new(0.143, -0.5, -2.1)},
            m9bayonet = {vec = Vector3.new(-0.029, -0, -1.674)},
        },

        --ak103 = {vec = Vector3.new(.8,-.15,-3), rot = Vector3.new(math.rad(80), math.rad(-60), math.rad(-90))},
        ak103 = {vec = Vector3.new(1, -0.264, -2.887), rot = vector3Rad(0, 30, -10)},

        ak47 = {vec = Vector3.new(0.9, -0.3, -2.8), rot = vector3Rad(20, -150, 20)},

        --glock17 = {vec = Vector3.new(0.12+.154, 0.1, -1.4), rot = vector3Rad(0, 30, -10)},
        glock17 = {vec = Vector3.new(0.325, -0.235, -1.33), rot = vector3Rad(80, -60, -180)},

        --deagle = {vec = Vector3.new(0, 0, -1.5)},
        deagle = {vec = Vector3.new(0.166, -0.108, -1.228), rot = vector3Rad(13.027, -156.446, 15.408)},

        --intervention = {vec = Vector3.new(0.5, 0, -3.5)},
        intervention = {vec = Vector3.new(-0.371, -0.007, -4.133), rot = vector3Rad(-14.478, 126.565, 26.565)},

        --vityaz = {vec = Vector3.new(0.5,0,-2.3)},
        vityaz = {vec = Vector3.new(0.429, -0.137, -1.786), rot = vector3Rad(20, -150, 20)},

        --acr = {vec = Vector3.new(0.5, -.18, -3), rot = Vector3.new(0,math.rad(rotDeg90),0)},
        acr = {vec = Vector3.new(0.654, -0.258, -3.028), rot = vector3Rad(-3.405, 10.28, -9.408)},

        --hkp30 = {vec = Vector3.new(0.25, 0, -1.3)},
        hkp30 = {vec = Vector3.new(0.233, -0.12, -1.287), rot = vector3Rad(20, 85, -10)}
    }
}

return Config