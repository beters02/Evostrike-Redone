local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Libraries = ReplicatedStorage:WaitForChild("Scripts"):WaitForChild("Libraries")
local CustomString = require(Libraries:WaitForChild("WeaponFireCustomString"))
local Math = require(Libraries:WaitForChild("Math"))
local WeaponRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Weapon")
local WeaponGetEvent = WeaponRemotes:WaitForChild("Get")
local FESpring = require(Libraries:WaitForChild("FESpring"))
local DefaultCameraWait = WeaponGetEvent:InvokeServer("FireCameraDownWait")

local Camera = {}
Camera.__index = Camera
Camera._defaults = {
	fireCameraMult = .2
}

-- Init Functions

function Camera.init(weaponName)
	local self = setmetatable({}, Camera)
	self.camera = workspace.CurrentCamera
	self.weaponVar = {currentBullet = 1, sprayReset = {x = 0, y = 0}, options = WeaponGetEvent:InvokeServer("Options", weaponName), recoiling = false}
	self.springs, self.springDefaults, self.springCurrents = self:CreateSprings()
	return self
end

function Camera:CreateSprings()
	local springs = {vec = FESpring.spring.new(Vector3.zero), shake = FESpring.spring.new(Vector3.zero)}
	local springDefaults = self:GetDefaultSpringProperties()
	local springCurrents = {}
	springs.vec.s, springs.vec.d = springDefaults.vec.speed, springDefaults.vec.damp
	springs.shake.s, springs.shake.d = springDefaults.shake.speed, springDefaults.shake.damp
	springCurrents.vec = {returnSpeed = springs.vec.s, returnDamp = springs.vec.d, modifier = 1}
	springCurrents.shake = {returnSpeed = springs.shake.s, returnDamp = springs.shake.d, modifier = 1}
	return springs, springDefaults, springCurrents
end

function Camera:GetDefaultSpringProperties()
	return {shake = self.weaponVar.options.fireShakeSpring, vec = self.weaponVar.options.fireVectorSpring}
end

-- Camera Functions

function Camera:Update(dt)
	local pos, returnPos = self.springs.shake.p, self.springs.vec.p
	self.camera.CFrame = self.camera.CFrame:Lerp(self.camera.CFrame * CFrame.Angles(pos.X, pos.Y, pos.Z) * CFrame.Angles(returnPos.X, returnPos.Y, returnPos.Z), dt * 60)
end

function Camera:Connect()
	RunService:BindToRenderStep("GunCamera", Enum.RenderPriority.Camera.Value + 3, function(dt)
		self:Update(dt)
	end)
end

function Camera:Disconnect()
	RunService:UnbindFromRenderStep("GunCamera")
end

-- Camera Weapon Functions

function Camera:GetSprayPatternKey()
	return self.weaponVar.options.sprayPattern[self.weaponVar.currentBullet], self.weaponVar.options.shakePattern[self.weaponVar.currentBullet]
end

function Camera:GetRecoilVector3(patternKey)
	local recoil = {x = patternKey[2], y = patternKey[1], z = patternKey[3]}
	return Vector3.new(recoil.x, recoil.y, recoil.z)
end

function Camera:ResetSprayReset()
	self.weaponVar.sprayReset = {x = 0, y = 0}
end

function Camera:ChangeSpringStats(springName, speed, damp)
	local newSpeed = speed
	local newDamp = damp
	if speed == "default" then
		newSpeed = self.springDefaults[springName].speed
	end
	if damp == "default" then
		newDamp = self.springDefaults[springName].damp
	end
	self.springs[springName]:ChangeStats(newSpeed or false, newDamp or false)
end

function Camera:FireSpring(currentBullet)
	self.weaponVar.currentBullet = currentBullet
	self.weaponVar.recoiling = true
	local nextTick = tick() + self.weaponVar.options.fireRate

	local patternKey, shakePatternKey = self:GetSprayPatternKey()
	if currentBullet == 1 then self:ResetSprayReset() end
	
	for i, v in pairs({vec = patternKey, shake = shakePatternKey}) do
		if v[4] then
			self.springCurrents[i].modifier = v[4]
		end
		if v[5] or v[6] then -- up speed/damp
			self:ChangeSpringStats(i, v[5], v[6])
		end
		if v[7] or v[8] then -- down speed/damp
			if v[7] then
				local new = v[7]
				if new == "default" then new = self.springDefaults[i].speed end
				self.springCurrents[i].returnSpeed = new
			end
			if v[8] then
				local new = v[8]
				if new == "default" then new = self.springDefaults[i].damp end
				self.springCurrents[i].returnDamp = new
			end
		end
	end

	local recoil = self:GetRecoilVector3(patternKey) * Camera._defaults.fireCameraMult
	local shakeRecoil = self:GetRecoilVector3(shakePatternKey) * Camera._defaults.fireCameraMult
	local vecMax = self.weaponVar.options.fireVectorSpring.max

	--local shakeVec = Math.vector3Min(Math.vector3Max(Vector3.new(shakeRecoil.x, shakeRecoil.Y, shakeRecoil.Z)/5, 1), 5) --TODO: set shake minimum
	local shakeVec = Math.vector3Min(Vector3.new(shakeRecoil.x, shakeRecoil.Y, shakeRecoil.Z)/5, 5)
	shakeVec *= self.springCurrents.shake.modifier * 20
	
	self.springs.shake:ChangeStats(57, 1)
	self.springs.shake:Accelerate(shakeVec)
	task.spawn(function()
		task.wait(self.springDefaults.shake.downWait or DefaultCameraWait)
		self.springs.shake:ChangeStats(50, 1)
		self.springs.shake:Accelerate(-Vector3.new(shakeVec.X * 0.8, shakeVec.Y * 0.8, 0))
	end)
	
	if not self.weaponVar.options.spread then
		local vecVec = Vector3.new(recoil.X, recoil.Y, recoil.Z) * self.springCurrents.vec.modifier
		if vecMax then
			vecVec = Math.vector3Min(vecVec, vecMax)
		end

		self.springs.vec:Accelerate(vecVec * 10)
		self.weaponVar.sprayReset.x += vecVec.X * 10
		self.weaponVar.sprayReset.y += vecVec.Y * 10
	end
	
	repeat task.wait() until tick() >= nextTick
	self.weaponVar.recoiling = false
end

function Camera:StopFire()
	if self.weaponVar.options.spread then return end
	
	local downAccelMod = self.weaponVar.options.downAccelerationModifier
	local accelMod = downAccelMod and (self.weaponVar.currentBullet >= downAccelMod.start and downAccelMod.mod or downAccelMod.default) or 1

	repeat task.wait() until not self.weaponVar.recoiling

	self:ChangeSpringStats("vec", self.springCurrents.vec.returnSpeed, self.springCurrents.vec.returnDamp)
	
	self.springs.vec:Accelerate(-Vector3.new(self.weaponVar.sprayReset.x, self.weaponVar.sprayReset.y, 0) * accelMod)

	self:ResetSprayReset()
end

return Camera