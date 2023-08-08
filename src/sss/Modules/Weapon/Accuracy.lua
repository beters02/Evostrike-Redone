local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

local States = require(Framework.ReplicatedStorage.Modules.States)
local Math = require(Framework.ReplicatedStorage.Modules.Math)

local Accuracy = {}
Accuracy.__index = Accuracy

local function quickVecAdd(vec, add)
	return Vector2.new(vec.X + math.random(-add, add), vec.Y + math.random(-add, add))
end

local function quickVecAddXY(vec, addX, addY)
	addX = addX > 0 and math.random(-addX, addX) or math.random(addX, -addX)
	addY = addY > 0 and math.random(-addY, addY) or math.random(addY, -addY)
	return Vector2.new(vec.X + addX, vec.Y + addY)
end

local function getMovementInaccuracyVector2(firstBullet, player, speed, weaponOptions)
	local toAdd = 0
	if not weaponOptions.accuracy.firstBullet or not firstBullet then
		toAdd = weaponOptions.accuracy.base
	end
	
	local movementSpeed = speed or player.Character.HumanoidRootPart.Velocity.magnitude
	if movementSpeed > 6 and movementSpeed < 12 then
		toAdd = weaponOptions.accuracy.walk
	elseif movementSpeed >= 12 then
		toAdd = weaponOptions.accuracy.run
	end
	
	if not States.Movement:GetState(player, "grounded") then
		toAdd += weaponOptions.accuracy.jump
	end
	
	local acc = quickVecAdd(Vector2.zero, toAdd)
	return acc
end

local function calculate(player, currentBullet, recoilVector3, speed, storedVar, weaponOptions, cvec2) -- cvec2 is client accuracy re-registration
	-- var
	local acc
	local offset = weaponOptions.fireVectorCameraOffset
	
	-- fire no vector recoil, only offset
	local new = Vector2.new(math.max(math.min(recoilVector3.Y, 0.1), -0.1), 1)
	
	-- grow vector offset for first 4 bullets
	-- bullets would shoot up after the first bullet without this
	if currentBullet < 6 then
		offset *= currentBullet/6
	end
	
	-- first bullet accuracy
	local first = false
	if currentBullet == 1 then
		first = true
		if weaponOptions.accuracy.firstBullet then
			new = Vector2.zero
		end
	else

		-- if the add vector is 0, don't keep climbing the vec recoil
		if new.Y ~= 0 then
			storedVar.lastYAcc = new.Y
		end
	end

	acc = cvec2 or getMovementInaccuracyVector2(first, player, speed, weaponOptions)
	storedVar.lastYAcc = acc.Y

	if weaponOptions.spread then
		new = quickVecAddXY(acc, new.X * offset.X, new.Y * offset.Y)
		return new, storedVar
	end
	
	new = Vector2.new(acc.X + (new.X * offset.X), acc.Y + (storedVar.lastYAcc * offset.Y))
	return new, storedVar
end



return Accuracy