--[[
	Variables
]]

export type CustomSpring = {
	Spring: any,
	ShoveVector: Vector3,
	UpdateFunction: (viewmodel: table, ...any) -> (),

	Shove: () -> (),
	Remove: () -> (),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local VMSprings = require(Framework.shc_vmsprings.Location)
local Math =  require(Framework.shfc_math.Location)
local Tables = require(Framework.shfc_tables.Location)
local viewmodelModel = ReplicatedStorage.Assets.Models.viewModel
local PlayerDied = Framework.Module.EvoPlayer.Events.PlayerDiedBindable
local PlayerData = require(Framework.Module.PlayerData)

local viewmodelModule = {}
viewmodelModule.cfg = Tables.clone(require(script.Parent:WaitForChild("config")))
viewmodelModule.storedClass = false

-- [[ Utility Functions ]]

function util_getVMStartCF(self)

	-- get default vm offset based on FOV & custom offset
	local _defoff = Vector3.new(
		self.vmX ~= 0 and self.vmX/3 or self.vmX,
		self.vmY ~= 0 and self.vmY/3 or self.vmY,
		self.vmZ ~= 0 and self.vmZ/3 or self.vmZ
	)

	if workspace.CurrentCamera.FieldOfView > 70 then
		-- every 5 fov we increment a specific amount
		local diff = workspace.CurrentCamera.FieldOfView - 70
		_defoff = Vector3.new(_defoff.X + (-0.04 * (diff/5)), 0, _defoff.Z + (0.07 * (diff/5)))
	end

	return self.camera.CFrame + self.camera.CFrame:VectorToWorldSpace(_defoff)
end

--[[ Init Functions ]]

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
    self.movementGet = self.char:WaitForChild("MovementScript").Events.Get
    self.cdt = 1/60

	-- playerdata
	local pd = PlayerData:Get()
	self.vmBob = pd.options.camera.vmBob
	self.vmX = pd.options.camera.vmX
	self.vmY = pd.options.camera.vmY
	self.vmZ = pd.options.camera.vmZ
    
    -- springs
    self:initDefaultSprings()
	self:initCustomSprings()

    -- connect
    self:connect()

	viewmodelModule.storedClass = self

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

function viewmodelModule:initDefaultSprings()
    self.springs = {}
    self.springs.bob = VMSprings:new(9, 50, 5, 3.5) --m, f, d, s
    self.springs.charMoveSway = VMSprings:new(9, 50, 4, 4)
    self.springs.mouseSway = VMSprings:new(9, 40, 2.5, 5)
    self.springs.mouseSwayRotation = VMSprings:new(9, 50, 4, 4)
end

function viewmodelModule:initCustomSprings()
	self.customsprings = {}
end

-- [[ Core ]]

function viewmodelModule:connect()
	if not self.cdt then
		self.cdt = 1/60
	end

	RunService:BindToRenderStep("ViewmodelCamera", Enum.RenderPriority.Camera.Value + 3, function(dt)
		self:update(self.cdt)
	end)

	self._fixedConnection = RunService.Stepped:Connect(function(t, dt)
		self.cdt = dt
	end)

	self._died = PlayerDied.Event:Connect(function()
		self:disconnect()
		viewmodelModule.storedClass = false
	end)

	for _, v in pairs({"vmX", "vmY", "vmZ", "vmBob"}) do
		self["_" .. v .. "Changed"] = PlayerData:PathValueChanged("options.camera." .. v, function(new)
			self[v] = new
		end)
	end
end

function viewmodelModule:disconnect()
    RunService:UnbindFromRenderStep("ViewmodelCamera")
	self._fixedConnection:Disconnect()
	self._died:Disconnect()
end

function viewmodelModule:update(dt)
	self.vmhrp.CFrame = util_getVMStartCF(self)
    self.vmhrp.CFrame = self.vmhrp.CFrame:ToWorldSpace(self:bob(dt)) * self:charMoveSway(dt) * self:mouseSway(dt)

	-- update custom springs
	if self.customsprings then
		for i, v: CustomSpring in pairs(self.customsprings) do
			v.UpdateFunction(self, dt)
		end
	end
end

function viewmodelModule:destroy()
    self.vm:Destroy()
    self:disconnect()
end

--[[ Viewmodel Spring Functions ]]

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

    local movementSway = Vector3.new(getBob(4.75 * self.vmBob, _s, _m), getBob(2.25 * self.vmBob, _s, _m), getBob(2.25 * self.vmBob, _s, _m))
	
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
    local mod = cfg.mod
    local spring = self.springs.charMoveSway
	
    -- get direction
	local directive = self.charhrp.CFrame:VectorToObjectSpace(self.hum.MoveDirection)
	local velocity = self.movementVel.Velocity.Magnitude * -.008
	--print(self.charhrp.CFrame:VectorToWorldSpace(self.movementVel.Velocity))

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

	-- set velocity max/min
	local velMax = 18 * -mod
	local velMagNum = (self.charhrp.Velocity.Magnitude * -mod)
	velMagNum = velMagNum < 0 and math.max(velMagNum, velMax) or math.min(-velMax, velMagNum)

	-- create shove
	local x = math.clamp(directive.X, cfg.minX, cfg.maxX) * velocity
	local y = math.clamp(self.charhrp.Velocity.Y, -cfg.maxY, cfg.maxY) * velMagNum
	local z = math.clamp(directive.Z, cfg.minZ, cfg.maxZ) * velocity
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
    local shove = Vector3.new((-MouseDelta.X  / 470), MouseDelta.Y / 185, 0)

	-- accelerate position shove
	spring:shove(shove)

	-- get rotation shove
	-- we min the rotation on the up Y axis so it doesn't go up too much
	local swaycfg = viewmodelModule.cfg.mousesway
	local rotShoveY = math.max(math.min(shove.Y, swaycfg.maxY), swaycfg.minY)
	local rotShove = Math.vector3Max(Math.vector3Min(shove, swaycfg.maxXZ), swaycfg.minXZ)
	rotShove = Vector3.new(rotShove.X, rotShoveY, rotShove.Z)
	
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
	return
end

-- [[ Custom Viewmodel Spring Functionality ]]

function viewmodelModule:addCustomSpring(ID: string, overwrite: boolean, spring: any, shove: Vector3, shoveFunction: () -> (), updateFunction: (viewmodel: table, ...any) -> ())
	if self.customsprings[ID] then
		if not overwrite then
			return self.customsprings[ID]
		end
		self:removeCustomSpring(ID)
	end
	self.customsprings[ID] = {
		Spring = spring,
		ShoveVector = shove,
		UpdateFunction = updateFunction,
		
		Shove = shoveFunction,
		Remove = function()
			self:removeCustomSpring(ID)
		end
	} :: CustomSpring
	return self.customsprings[ID]
end

function viewmodelModule:removeCustomSpring(ID: string)
	if not self.customsprings[ID] then return end
	self.customsprings[ID] = nil
end

return viewmodelModule