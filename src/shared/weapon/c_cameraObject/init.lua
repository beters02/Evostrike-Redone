local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local WeaponGet = ReplicatedStorage.weapon.remote.get
local Recoil = require(Framework.shfc_recoil.Location)

local CameraObject = {}
CameraObject.__index = CameraObject

function CameraObject.new(weaponName)
    local self = {}
    
    -- initialize recoil functions
    --self = setmetatable(Recoil, self)
    for i, v in pairs(Recoil) do
        self[i] = v
    end

    -- initialize variables
    self.camera = workspace.CurrentCamera
	self.weaponVar = {options = WeaponGet:InvokeServer("Options", weaponName), recoiling = false, modifier = 1, currentBullet = 1, totalRecoiledVector = Vector3.zero, thread = false}
    self.weaponVar.camReset = self.weaponVar.options.cameraRecoilReset or self.weaponVar.options.recoilReset
    self.weaponVar.camModifier = 1
    self.weaponVar.vecModifier = 1
    self.weaponVar.lastSavedRecVec = Vector3.zero
    self.weaponVar.isSpread = self.weaponVar.options.spread or false

    return self
end

return CameraObject