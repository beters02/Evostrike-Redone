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

local rate = 1/60
local next = tick()
local last = tick()

local nextPosUpdate = tick()
local pos, returnPos

function Camera:Update(dt)
	if tick() >= nextPosUpdate then
		pos, returnPos = self.springs.shake.p, self.springs.vec.p
	end

	self.camera.CFrame = self.camera.CFrame:Lerp(self.camera.CFrame * CFrame.Angles(pos.X, pos.Y, pos.Z) * CFrame.Angles(returnPos.X, returnPos.Y, returnPos.Z), dt * 60)
		
	next = tick() + rate
	last = tick()
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

local WeaponFireCustomString = require(Libraries.WeaponFireCustomString)

function Camera:GetSprayPatternKey()
	return self.weaponVar.options.sprayPattern[self.weaponVar.currentBullet], self.weaponVar.options.shakePattern[self.weaponVar.currentBullet]
end

function Camera:GetRecoilVector3(patternKey)
	local new = {}
	for i, v in pairs(patternKey) do
		if type(v) == "string" then
			new[i] = WeaponFireCustomString.duringStrings(v)
		else
			new[i] = v
		end
	end
	local recoil = {x = new[2], y = new[1], z = new[3]}
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

	-- set var
	self.weaponVar.currentBullet = currentBullet
	self.weaponVar.recoiling = true
	local nextTick = tick() + self.weaponVar.options.fireRate

	-- get spray pattern keys
	local patternKey, shakePatternKey = self:GetSprayPatternKey()

	-- reset spray reset if currbullet is 1
	if currentBullet == 1 then self:ResetSprayReset() end
	
	-- pattern key processing
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

	-- get recoil vectors and max
	local recoil = self:GetRecoilVector3(patternKey) * Camera._defaults.fireCameraMult
	local shakeRecoil = self:GetRecoilVector3(shakePatternKey) * Camera._defaults.fireCameraMult
	local vecMax = self.weaponVar.options.fireVectorSpring.max

	-- we gotta get rid of all of the modifiers dude
	local shakeVec = Math.vector3Min(Vector3.new(shakeRecoil.X, shakeRecoil.Y, shakeRecoil.Z)/5, 5)
	shakeVec *= self.springCurrents.shake.modifier * 20

	-- shake spring processing
	self.springs.shake:ChangeStats(self.springDefaults.shake.speed, self.springDefaults.shake.damp)
	task.wait()
	self.springs.shake:Accelerate(shakeVec)

	task.spawn(function()
		local modifier = self.springDefaults.shake.returnModifier or 1
		task.wait(self.springDefaults.shake.downWait or DefaultCameraWait)
		
		if self.springDefaults.shake.returnDamp or self.springDefaults.shake.returnSpeed then
			self.springs.shake:ChangeStats(self.springDefaults.shake.returnSpeed or false, self.springDefaults.shake.returnDamp or false)
		end
		task.wait()

		self.springs.shake:Accelerate(-Vector3.new(shakeVec.X, shakeVec.Y, 0) * modifier)
	end)
	
	-- vector camera recoil (for spray patterns only)
	if not self.weaponVar.options.spread then
		local vecVec = Vector3.new(recoil.X, recoil.Y, recoil.Z) * self.springCurrents.vec.modifier
		if vecMax then
			vecVec = Math.vector3Min(vecVec, vecMax)
		end
		
		self.springs.vec:ChangeStats(self.springDefaults.vec.speed, self.springDefaults.vec.damp)
		task.wait()

		self.springs.vec:Accelerate(vecVec)
		self.weaponVar.sprayReset.x += vecVec.X
		self.weaponVar.sprayReset.y += vecVec.Y
	end
	
	repeat task.wait() until tick() >= nextTick
	self.weaponVar.recoiling = false
end

function Camera:StopFire()
	if self.weaponVar.options.spread then return end

	local accelMod = self.springDefaults.vec.returnModifier or 1

	repeat task.wait() until not self.weaponVar.recoiling
	self.springs.vec:ChangeStats(self.springDefaults.vec.returnSpeed or false, self.springDefaults.vec.returnDamp or false)

	task.wait()
	self.springs.vec:Accelerate(-Vector3.new(self.weaponVar.sprayReset.x, self.weaponVar.sprayReset.y, 0) * accelMod)

	self:ResetSprayReset()
end

return Camera