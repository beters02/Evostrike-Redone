--[[
    Configuration
]]

local bobcfg = {speed = 3.3, modifier = .3, clamp = 0.033}
local charmoveswaycfg = {maxX = .2, maxY = .4, mod = 0.007}

--[[
	Variables
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Libraries = ReplicatedStorage:WaitForChild("Scripts"):WaitForChild("Libraries")
local RunService = game:GetService("RunService")
local VMSprings = require(Libraries:WaitForChild("ViewmodelSprings"))
local MovementState = require(ReplicatedStorage.Scripts:WaitForChild("Modules").States).Movement
local Math = require(Libraries:WaitForChild("Math"))

local vm
local camera = workspace.CurrentCamera
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp
local charhrp = char:WaitForChild("HumanoidRootPart")
local movementVel = charhrp:WaitForChild("movementVelocity")
local movementGet = char:WaitForChild("MovementScript").Events.Get
local equippedWeapon = false
local cdt = 1/60

-- springs
local bobSpring = VMSprings:new(9, 50, 4, 6) --m, f, d, s
local charMoveSwaySpring = VMSprings:new(9, 30, 4, 6)
local mouseSwaySpring = VMSprings:new(9, 40, 2, 6)
local mouseSwayRotationSpring = VMSprings:new(9, 50, 4, 6)
local weaponFireSpring = VMSprings:new(9, 75, 4, 6)

--[[
	Functions
]]


local function getBob(addition, speed, modifier)
	return math.sin(tick()*addition*speed)*modifier
end

local function getClamp(n, clamp)
	return math.clamp(n, -clamp, clamp)
end

local function isJumping()
	return not movementGet:Invoke()
end

local function createViewmodel()
	local viewModel = ReplicatedStorage:WaitForChild("Objects"):WaitForChild("viewModel")
	local vm = viewModel:Clone()
	if camera:FindFirstChild("viewModel") then
		camera.viewModel:Destroy()
		RunService:UnbindFromRenderStep("ViewmodelCamera")
	end
	vm.Parent = camera
	return vm
end

local function bob(dt)

    --var
    local velocity = movementVel.Velocity
	local magnitude = velocity.Magnitude

    local _s = bobcfg.speed
    local _m = bobcfg.modifier
    local _c = bobcfg.clamp
    local spring = bobSpring

    local movementSway = Vector3.new(getBob(4.75, _s, _m), getBob(2.25, _s, _m), getBob(2.25, _s, _m))
	
    -- don't bob if jumping
	if isJumping() then magnitude = 0 end

    -- create shove var
	local shov = (movementSway / 100 * magnitude)
	local x = (shov.X * (velocity.X * -100))
	
	--shove spring
	shov = Vector3.new(getClamp(x, _c), getClamp(shov.Y, _c), getClamp(shov.Z, _c))
    spring:shove(shov * (dt * 60))

    -- update
    local updatedBob = spring:update(dt)
	local newcf = CFrame.new(updatedBob.Y, updatedBob.X, 0)
    return newcf
end

local function charMoveSway(dt)

    --var
	local hum = char.Humanoid
	local charHrp = char.HumanoidRootPart
	local oldVel = movementVel.Velocity.Magnitude
	local mod = charmoveswaycfg.mod
	local velocity = oldVel * -.005
    local spring = charMoveSwaySpring
	
	-- set to max or 0
	if math.abs(velocity) >= .0001 then
		if velocity < 0 then
			velocity = -charmoveswaycfg.maxX
		else
			velocity = charmoveswaycfg.maxX
		end
	else
		velocity = 0
	end
	
    -- get direction
	local directive = charHrp.CFrame:VectorToObjectSpace(hum.MoveDirection)
	local max = charmoveswaycfg.maxX
	local ymax = charmoveswaycfg.maxY

    -- if jumping change max
	if isJumping(char) then
		max = 0.2
		ymax = 0.42
	end

	-- set velocity max/min
	local velMax = 18 * -mod
	local velMagNum = (charHrp.Velocity.Magnitude * -mod)
	velMagNum = velMagNum < 0 and math.max(velMagNum, velMax) or math.min(-velMax, velMagNum)

	-- create shove
	local x = math.clamp(directive.X, -max, max) * velocity
	local y = math.clamp(charHrp.Velocity.Y, -ymax, ymax) * velMagNum
	local z = math.clamp(directive.Z, -max, max) * velocity
	local shove = (Vector3.new(x, y, z))

	-- accelerate shove
	-- needs to be multiplied by dt due to the velocity variable
	spring:shove(shove * (dt*60))

	--update
	local updatedSpring = spring:update(dt)
	return CFrame.new(updatedSpring.X, updatedSpring.Y, updatedSpring.Z)
end

local function mouseSway(dt)

	--var
	local spring = mouseSwaySpring
	local rotspring = mouseSwayRotationSpring
	
	--shove by mouseDelta
	local MouseDelta = UserInputService:GetMouseDelta()
	-- get position shove
    local shove = Vector3.new((-MouseDelta.X  / 500), MouseDelta.Y / 200, 0)

	-- accelerate position shove
	spring:shove(shove)

	-- get rotation shove
	-- we min the rotation on the up Y axis so it doesn't go up too much
	local rsy = math.max(math.min(shove.Y, 0.02), -0.035)
	local rotShove = Math.vector3Max(Math.vector3Min(shove, 0.03), -0.03)
	rotShove = Vector3.new(rotShove.X, rsy, rotShove.Z)
	
	-- accelerate rotation shove
	rotspring:shove(rotShove)
	
	--update
	local uss = spring:update(dt)
	local rss = rotspring:update(dt)

	return CFrame.new(uss.X, uss.Y, 0) * CFrame.Angles(rss.Y, rss.X, 0)
end

local function jumpSway(dt)

	-- var
	local spring = charMoveSwaySpring

	local y = (math.random(75, 100) / 100) * 0.7
	local shov = Vector3.new(0, y, 0)

	-- shove
	spring:shove(shov)
	
	-- test shove mouse sway
	--mouseSwayRotationSpring:shove((shov/7))

	return
end

local function weaponFireSway(dt, x, y)
	local spring = weaponFireSpring
	local shov = Vector3.new()
end

local count = 0
local VMSprings = {}

local function updateVMSprings(dt)
	if count > 0 then
		for i, v in pairs(VMSprings) do
			local func = v[2]
			hrp.CFrame = func(dt, hrp)
		end
	end
end

function connectVMSpring(connect: boolean, spring, springName, func)
	if connect then
		VMSprings[springName] = {spring, func}
		count += 1
	else
		disconnectVMSpring(spring)
	end	
end

function disconnectVMSpring(springName)
	VMSprings[springName] = nil
	count -= 1
end

function update(dt)
	cdt = dt
	hrp.CFrame = camera.CFrame
    hrp.CFrame = hrp.CFrame:ToWorldSpace(bob(dt)) * charMoveSway(dt) * mouseSway(dt)

	-- VMSpringAnimation connect extra cfs
	updateVMSprings(dt)

end

--[[
	Init
]]

vm = createViewmodel()
hrp = vm:WaitForChild("HumanoidRootPart")

--[[
	Connections
]]

RunService:BindToRenderStep("ViewmodelCamera", Enum.RenderPriority.Camera.Value + 3, update)

script:WaitForChild("Jump").Event:Connect(function()
	jumpSway(cdt)
end)

script:WaitForChild("ConnectVMSpring").Event:Connect(connectVMSpring)