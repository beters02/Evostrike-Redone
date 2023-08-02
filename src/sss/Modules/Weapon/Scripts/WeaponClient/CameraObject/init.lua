local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Weapon")
local WeaponGetEvent = WeaponRemotes:WaitForChild("Get")
local Libraries = ReplicatedStorage:WaitForChild("Scripts"):WaitForChild("Libraries")
local FESpring = require(Libraries:WaitForChild("FESpring"))

-- test

local CameraObject = {}
CameraObject.__index = CameraObject

function CameraObject.new(weaponName)
    local self = {}
    
    -- initialize recoil functions
    for i, v in pairs(require(script.Recoil)) do
        self[i] = v
    end

    -- initialize variables
    self.camera = workspace.CurrentCamera
	self.weaponVar = {options = WeaponGetEvent:InvokeServer("Options", weaponName), recoiling = false, modifier = 1, currentBullet = 1, totalRecoiledVector = Vector3.zero, thread = false}
    self.weaponVar.camReset = self.weaponVar.options.cameraRecoilReset or self.weaponVar.options.recoilReset
    self.weaponVar.camModifier = 1
    self.weaponVar.vecModifier = 1

    -- test spring
    self.testSpring = FESpring.spring.new(Vector3.zero)
    self.testSpring.s = 45
    self.testSpring.d = 0.8

    return self
end

return CameraObject