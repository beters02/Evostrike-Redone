--[[
	Variables
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local VMSprings = require(Framework.shc_vmsprings.Location)
local Math =  require(Framework.shfc_math.Location)
local Tables = require(Framework.shfc_tables.Location)
local viewmodelModel = ReplicatedStorage:WaitForChild("main"):WaitForChild("obj"):WaitForChild("viewModel")

local viewmodelModule = {}
viewmodelModule.cfg = Tables.clone(require(script.Parent:WaitForChild("config")))

--[[ init functions ]]

function viewmodelModule.initialize()
    local self = viewmodelModule
    self.player = game:GetService("Players").LocalPlayer
    self.char = self.player.Character or self.player.CharacterAdded:Wait()
    self.hum = self.char:WaitForChild("Humanoid")
    self.charhrp = self.char:WaitForChild("HumanoidRootPart")
    self.camera = workspace.CurrentCamera
    
    self.vm = self:createViewmodel()
    self.vmhrp = self.vm:WaitForChild("HumanoidRootPart")
    
    self.movementVel = self.charhrp:WaitForChild("movementVelocity")
    self.movementGet = self.char:WaitForChild("movementScript").Events.Get
    --local equippedWeapon = false
    self.cdt = 1/60
    
    -- springs
    self:initSprings()

    -- connect
    self:connect()
    return self
end

function viewmodelModule:createViewmodel()
	local viewModel = viewmodelModel
	local vm = viewModel:Clone()
	if self.camera:FindFirstChild("viewModel") then
		self.camera.viewModel:Destroy()
		RunService:UnbindFromRenderStep("ViewmodelCamera")
	end
	vm.Parent = self.camera
	return vm
end

function viewmodelModule:initSprings()
    self.springs = {}
    self.springs.bob = VMSprings:new(9, 50, 4, 6) --m, f, d, s
    self.springs.charMoveSway = VMSprings:new(9, 30, 4, 6)
    self.springs.mouseSway = VMSprings:new(9, 40, 2, 6)
    self.springs.mouseSwayRotation = VMSprings:new(9, 50, 4, 6)
    self.springs.weaponFire = VMSprings:new(9, 75, 4, 6)
end


--[[
	Functions
]]

local function getBob(addition, speed, modifier)
	return math.sin(tick()*addition*speed)*modifier
end

local function getClamp(n, clamp)
	return math.clamp(n, -clamp, clamp)
end

function viewmodelModule:isJumping()
	return not self.movementGet:Invoke()
end

function viewmodelModule:bob(dt)

    --var
    local velocity = self.movementVel.Velocity
	local magnitude = velocity.Magnitude

    local bcfg = self.cfg.bob
    local _s = bcfg.speed
    local _m = bcfg.modifier
    local _c = bcfg.clamp
    local spring = self.springs.bob

    local movementSway = Vector3.new(getBob(4.75, _s, _m), getBob(2.25, _s, _m), getBob(2.25, _s, _m))
	
    -- don't bob if jumping
	if self:isJumping() then magnitude = 0 end

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

function viewmodelModule:charMoveSway(dt)

    --var
    local cfg = self.cfg.charmovesway
	local oldVel = self.movementVel.Velocity.Magnitude
    local mod = cfg.mod
	local velocity = oldVel * -.005
    local spring = self.springs.charMoveSway
	
	-- set to max or 0
	if math.abs(velocity) >= .0001 then
		if velocity < 0 then
			velocity = -cfg.maxX
		else
			velocity = cfg.maxX
		end
	else
		velocity = 0
	end
	
    -- get direction
	local directive = self.charhrp.CFrame:VectorToObjectSpace(self.hum.MoveDirection)
	local max = cfg.maxX
	local ymax = cfg.maxY

    -- if jumping change max
	if self:isJumping() then
		max = 0.2
		ymax = 0.42
	end

	-- set velocity max/min
	local velMax = 18 * -mod
	local velMagNum = (self.charhrp.Velocity.Magnitude * -mod)
	velMagNum = velMagNum < 0 and math.max(velMagNum, velMax) or math.min(-velMax, velMagNum)

	-- create shove
	local x = math.clamp(directive.X, -max, max) * velocity
	local y = math.clamp(self.charhrp.Velocity.Y, -ymax, ymax) * velMagNum
	local z = math.clamp(directive.Z, -max, max) * velocity
	local shove = (Vector3.new(x, y, z))

	-- accelerate shove
	-- needs to be multiplied by dt due to the velocity variable
	spring:shove(shove * (dt*60))

	--update
	local updatedSpring = spring:update(dt)
	return CFrame.new(updatedSpring.X, updatedSpring.Y, updatedSpring.Z)
end

function viewmodelModule:mouseSway(dt)

	--var
	local spring = self.springs.mouseSway
	local rotspring = self.springs.mouseSwayRotation
	
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

function viewmodelModule:jumpSway(dt)

	-- var
	local spring = self.springs.charMoveSway

	local y = (math.random(75, 100) / 100) * 0.7
	local shov = Vector3.new(0, y, 0)

	-- shove
	spring:shove(shov)
	
	-- test shove mouse sway
	--mouseSwayRotationSpring:shove((shov/7))

	return
end

function viewmodelModule:weaponFireSway(dt, x, y)
	local spring = self.springs.weaponFireSway
	local shov = Vector3.new()
end

local count = 0
local VMSprings = {}

function viewmodelModule:updateVMSprings(dt)
	if count > 0 then
		for i, v in pairs(VMSprings) do
			local func = v[2]
			self.vmhrp.CFrame = func(dt, self.vmhrp)
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

function viewmodelModule:update(dt)
	self.cdt = dt
	self.vmhrp.CFrame = self.camera.CFrame
    self.vmhrp.CFrame = self.vmhrp.CFrame:ToWorldSpace(self:bob(dt)) * self:charMoveSway(dt) * self:mouseSway(dt)

	-- VMSpringAnimation connect extra cfs
	self:updateVMSprings(dt)
end

function viewmodelModule:connect()
    RunService:BindToRenderStep("ViewmodelCamera", Enum.RenderPriority.Camera.Value + 3, function(dt)
        self:update(dt)
    end)
end

function viewmodelModule:disconnect()
    RunService:UnbindFromRenderStep("ViewmodelCamera")
end

function viewmodelModule:destroy()
    self.vm:Destroy()
    self:disconnect()
end

return viewmodelModule