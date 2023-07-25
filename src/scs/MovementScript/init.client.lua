--[[ TODO ]]
--[[

	- Add particles for walking/landing/dashing

]]

-- [[ Services ]]
local Players = game:GetService("Players")
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService("RunService")

-- [[ Define Local Variables]]
local Inputs
local Events = script:WaitForChild("Events")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local collider = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")

local cameraLook = Vector3.new()
local cameraYaw = Vector3.new()
local currentInputSum = {Forward = 0, Side = 0}
local currentDT = 1/60
local partYRatio
local partZRatio

local playerGrounded = false
local playerVelocity = Vector3.zero
local jumping = false
local jumpCooldown = false
local jumpDebounce = false
local inAir = false
local landing = false

local landed = Events:WaitForChild("Landed")
local movementState = require(game:GetService("ReplicatedStorage"):WaitForChild("Scripts"):WaitForChild("Modules"):WaitForChild("States")).Movement

--[[ 
	Variables for Custom Movement Abilities
]]
local dashing = false
local dashVariables = {
	trigger = false,
	direction = Vector3.zero,
	strength = 0,
	upstrength = 0
}

local function frameWait(frames)
	for i = 1, frames do
		RunService.RenderStepped:Wait()
	end
end

--[[
	Movement Scope
]]
local Movement = {
	
	-- constants
	player = player,
	character = character,
	camera = camera,
	collider = collider,
	currentDT = currentDT,
	head = head,
	
	-- mut
	rayYLength = nil,
	rayXLength = 0.4,
	
	movementPosition = nil,
	movementPositionD = 125,
	movementPositionP = 14000,
	movementPositionForce = 400000,
	
	movementVelocity = nil,
	movementVelocityP = 1500,
	movementVelocityForce = 300000,
	
}
Movement.__index = Movement

--[[
	Init Movement Extrensic Module Functions & Configuration
	
	This will set all of the Modules functions variables into this "Movement" space.
	Variables will replicate as long as the function is called with ":". (Movement:GetMovementVelocity)
]]

-- extract configuration variables and put them in the scope
local config = require(script.Configuration)
for i, v in pairs(config) do
	Movement[i] = v
end

--create YLength after config variables are added
Movement.rayYLength = Movement.playerTorsoToGround + Movement.movementStickDistance

-- extract movement functions and put them in the Movement scope
for i, v in pairs(setmetatable(require(script.Functions), Movement)) do
	if not Movement[i] then
		Movement[i] = v
	end
end

-- extract children of functions
for i, v in pairs(script.Functions:GetChildren()) do
	if not Movement[v.Name] then
		Movement[v.Name] = require(v)
	end
end

-- extract physics functions
for i, v in pairs(setmetatable(require(script.Physics), Movement)) do
	if not Movement[i] then
		Movement[i] = v
	end
end

--[[ Process Movement Functions ]]

--[[
	@title  		- Movement.Air

	@summary
]]

function Movement.Air()
	Movement.movementPosition.maxForce = Vector3.new()
	--Movement.movementVelocity.velocity = Movement:GetAirVelocity(Movement.movementVelocity.Velocity)
	Movement:ApplyAirVelocity()
	Movement.movementVelocity.maxForce = Movement:GetMovementVelocityAirForce()
end

--[[
	@title  		- Movement.Jump

	@summary
]]

function Movement.Jump(velocity)
	Movement.jumpGrace = tick() + Movement.jumpTimeBeforeGroundRegister -- This is how i saved the glitchy mousewheel jump
	collider.Velocity = Vector3.new(collider.Velocity.X, velocity, collider.Velocity.Z)
	Movement.Air()
end

--[[
	@title  		- Movement.Run

	@summary
]]

function Movement.Run(hitPosition)
	Movement.movementPosition.position = hitPosition + Vector3.new(0, Movement.playerTorsoToGround, 0)
	Movement.movementPosition.maxForce = Vector3.new(0, Movement.movementPositionForce, 0)
	--Movement.movementVelocity.Velocity = Movement:GetGroundVelocity(Movement.movementVelocity.Velocity)
	Movement.movementVelocity.maxForce = Movement:GetMovementVelocityForce()
	Movement.movementVelocity.P = Movement.movementVelocityP
	Movement:ApplyGroundVelocity()
end

--[[
	@title 			- Movement.Land
	@summary
					- Produces a movement decrease for a specified time and decrease amount.
					- Doesn't stop at goal, only stops after time is reached. 

	@param[opt]		- {number} decrease - Amount goal to decrease current movement speed by.
					- default: Movement.landingMovementDecrease

	@param[opt]		- {number} waitTime - Total length of speed decrease.
					- default: Movement.landingMovementDecreaseLength

	@param[opt]		- {number} iterations - Total loop iterations
					- default: 12
	
	@return			- {void}
]]
function Movement.Land(decrease, waitTime, iterations)
	--print('landed')

	decrease = decrease or Movement.landingMovementDecrease
	waitTime = waitTime or Movement.landingMovementDecreaseLength
	iterations = iterations or 12
	landing = true

	local currentVelocity = Movement.movementVelocity.Velocity
	local currentSpeed = currentVelocity.Magnitude
	local goal
	local sub
	local frictionApplied = false

	-- avoid / 0 errors
	if currentSpeed <= 0 then
		landing = false
		return
 	end

	-- get the goal speed
	local goal = Movement.movementVelocity.Velocity.Magnitude * Movement.landingMovementDecrease

	-- get the total amount of speed to subtract per iteration
	local sub = iterations / goal

	-- get the total amount to wait per iteration
	waitTime = Movement.landingMovementDecreaseLength / iterations


	for i = iterations, 1, -1 do
		--print('iteration ' .. tostring(i))

		local newVelocity = Movement.movementVelocity.Velocity

		-- when the player jumps, we want to cancel the land delay so they can hit bhops
		if jumping or inAir then
			--print("jump cancel")
			break
		end

		-- if theres no movement input, we only want to apply friction
		if Movement.currentInputSum.Forward == 0 and Movement.currentInputSum.Side == 0 then
			if not frictionApplied then
				frictionApplied = true
				Movement:ApplyFriction(1)
			end
			task.wait(waitTime)
			continue
		elseif frictionApplied then
			frictionApplied = false
		end
		
		-- if sub < 1 then we DONT want to divide, we multiply by the decimal instead
		local s = sub < 1 and (sub * i)/iterations or (sub/i)/iterations

		-- for the first two frames, only slow by a quarter to allow bhops
		if i > iterations - 3 then
			s += (s * .25)
		end
		
		-- set new velocity variable
		newVelocity *= s

		-- if newVelocity is lower than what we want, we set the minimum to goal
		if newVelocity.Magnitude < goal then
			newVelocity = newVelocity.Unit * math.max(newVelocity.Magnitude, goal)
		end

		-- apply velocity
		Movement.movementVelocity.Velocity = newVelocity
		
		-- break on land end
		if i == 1 then
			--print('land delay finished')
			break
		end

		task.wait(waitTime)
	end

	landing = false
end

--[[
	Movement Abilities
]]

function Movement.RegisterDashVariables(strength, upstrength)
	dashVariables.strength = strength
	dashVariables.upstrength = upstrength
	if currentInputSum.Forward == 0 and currentInputSum.Side == 0 then
		dashVariables.direction = collider.CFrame.LookVector
	else
		dashVariables.direction = ((currentInputSum.Forward * collider.CFrame.LookVector) + (currentInputSum.Side * -collider.CFrame.RightVector)).Unit
	end
	dashVariables.trigger = true
end

function Movement.Dash()
	dashing = true
	
	if playerGrounded then
		Movement.Jump(dashVariables.upstrength)
	end
	
	local newVel = (dashVariables.direction * dashVariables.strength)
	newVel = Vector3.new(newVel.X, collider.Velocity.Y, newVel.Z)
	collider.Velocity = newVel
	Movement.Air()
	
	playerGrounded = false
	inAir = tick()
	
	task.wait(0.01)
	
	landed.Event:Wait()
	dashing = false
	Movement.Land(0.6)
end

--[[
	Inputs
]]

Inputs = {}
Inputs.Keys = {
	Forward = {"W", false},
	Backward = {"S", false},
	Left = {"A", false},
	Right = {"D", false},
	--Jump = {"Space", false}
	Jump = {"MouseWheel", false}
}

Inputs.FormattedKeys = {
	W = 0,
	S = 0,
	A = 0,
	D = 0,
	--Space = 0
	MouseWheel = 0
}

function Inputs.FormatKeys()
	Inputs.FormattedKeys = {}
	for i, v in pairs(Inputs.Keys) do
		Inputs.FormattedKeys[v[1]] = v[2]
	end
end

function Inputs.OnInput(input) -- began and end
	if player:GetAttribute("Typing") then return end
	
	local inputState
	if input.UserInputState == Enum.UserInputState.Begin then
		inputState = true
	elseif input.UserInputState == Enum.UserInputState.End then
		inputState = false
	else
		return
	end 

	if input.UserInputType == Enum.UserInputType.Keyboard then
		--direct key name
		local key = input.KeyCode.Name
		if Inputs.FormattedKeys[key] ~= nil then
			Inputs.FormattedKeys[key] = inputState and 1 or 0
		end
	end
end

--mousewheel jump detection
local changing = false

local function RegisterMouseWheelInput()
	Inputs.FormattedKeys[Inputs.Keys.Jump[1]] = 1
	task.wait()
	Inputs.FormattedKeys[Inputs.Keys.Jump[1]] = 0
	changing = false
end

function Inputs.OnInputChange(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel and Inputs.Keys.Jump[1] == "MouseWheel" then
		RegisterMouseWheelInput()
	end
end

function Inputs.UpdateMovementSum()
	currentInputSum.Forward = Inputs.FormattedKeys[Inputs.Keys.Forward[1]] + -Inputs.FormattedKeys[Inputs.Keys.Backward[1]]
	currentInputSum.Side = Inputs.FormattedKeys[Inputs.Keys.Left[1]] + -Inputs.FormattedKeys[Inputs.Keys.Right[1]]
	local stickingValues = Movement:IsSticking()
	if stickingValues then
		currentInputSum.Forward -= (math.abs(currentInputSum.Forward) > 0 and stickingValues.forward[1] + stickingValues.forward[2]) or 0
		currentInputSum.Side -= (math.abs(currentInputSum.Side) > 0 and stickingValues.side[1] + stickingValues.side[2]) or 0
	end
	Movement.currentInputSum = currentInputSum
end

--[[
	Main Scope
]]
local prevUpdateTime = nil
local updateDT = 1/60
local inAirMovementState = false

--local updateRate = 1/64
--local nxt = tick()

function Update(dt)
	if not hum or (hum and hum.Health <= 0) then return end
	
	--if tick() < nxt then return end
	--nxt = tick() + updateRate
	
	currentDT = dt
	Movement.currentDT = dt
	
	Inputs.UpdateMovementSum()
	
	cameraYaw = Movement:GetYaw()
	cameraLook = cameraYaw.lookVector
	Movement.cameraYaw = cameraYaw
	Movement.cameraLook = cameraLook
	
	if cameraLook == nil then return end
	
	local hitPart, hitPosition, hitNormal, yRatio, zRatio, ladderTable = Movement:FindCollisionRay()
	playerGrounded = hitPart and true or false
	playerVelocity = collider.Velocity - Vector3.new(0, collider.Velocity.y, 0)
	
	if Movement.jumpGrace and tick() < Movement.jumpGrace then
		playerGrounded = false
	end
	
	--local playerGrounded, groundHeight = Movement.GetCollisionCylinder()
	
	-- [[ LANDING REGISTRATION ]]
	if playerGrounded and inAir and (not Movement.jumpGrace or tick() >= Movement.jumpGrace) then

		-- only register land after given time in air
		if tick() >= inAir + Movement.minInAirTimeRegisterLand and not landing then

			-- set inair to false before landing because Land has an inAir check, and we are not in the air
			inAir = false

			Movement.Land()
			landed:Fire()
		else

			-- if we didn't register a land, we jump
			Movement.Run(hitPosition)
		end
		
		-- set player MovementState
		movementState:SetState(player, "grounded", true)

		inAir = false
		inAirMovementState = false
		return
	end
	
	-- [[ INPUT REGISTRATION ]]
	if Inputs.FormattedKeys[Inputs.Keys.Jump[1]] > 0 then
		jumping = true
	else
		jumping = false
		if playerGrounded and jumpCooldown then
			jumpCooldown = false
		end
	end
	
	-- set rotation
	Movement:SetCharacterRotation()

	-- dash trigger
	if dashVariables.trigger then
		dashVariables.trigger = false
		Movement.Dash()

		-- maybe set jumping to false in this instance so Movement.Jump() isnt called twice since the dash calls it
		-- jumping = false
	end
	
	-- [[ GROUND MOVEMENT ]]
	if playerGrounded and not dashing then
		if jumping then
			
			-- call ground movement if on jump cooldown and trying to jump
			if jumpCooldown or inAir then
				Movement.Run(hitPosition)
			else
				
				-- [[ JUMP MOVEMENT ]]
				jumpDebounce = true
				if not Movement.autoBunnyHop and Inputs.Keys.Jump[1] ~= "MouseWheel" then --jump cooldown start
					jumpCooldown = true
				end

				Movement.Jump(Movement.jumpVelocity)

				inAir = tick()

				if not inAirMovementState then
					inAirMovementState = true
					movementState:SetState(player, "grounded", false)
				end
				
			end
			
		else
			
			-- [[ RUN MOVEMENT ]]
			Movement.Run(hitPosition)
			
		end
		
	else
		
		-- [[ AIR MOVEMENT ]]
		
		-- set inAir to current time if this is first instance of being in the air (start falling)
		if not inAir then
			inAir = tick()
		end

		-- get velocity
		Movement.Air()

		-- set grounded MovementState to false, only if it hasn't been set already
		-- this is so the function wont overload the server with remotes
		if not inAirMovementState then
			inAirMovementState = true
			movementState:SetState(player, "grounded", false)
		end
		
	end
end

function SetDeltaTime() --seconds
	local UpdateTime = tick() 
	if prevUpdateTime ~= nil then
		updateDT = (UpdateTime - prevUpdateTime)
	else
		updateDT = 1/60
	end
	prevUpdateTime = UpdateTime
end

function UpdateLoop()
	SetDeltaTime()
	Update(updateDT)
end

function Main()
	local a = player.Character:FindFirstChildOfClass("Humanoid") or player.Character:WaitForChild("Humanoid")
	a.PlatformStand = true
	Init()
	UserInputService.InputBegan:Connect(Inputs.OnInput)
	UserInputService.InputEnded:Connect(Inputs.OnInput)
	UserInputService.InputChanged:Connect(Inputs.OnInputChange)
	RunService:BindToRenderStep("updateLoop", 1, UpdateLoop)
	
	-- connect movement abilities
	script.Events.Dash.Event:Connect(Movement.RegisterDashVariables)
end

function Init()
	local movementPosition = Instance.new("BodyPosition", collider)
	movementPosition.Name = "movementPosition"
	movementPosition.D = Movement.movementPositionD
	movementPosition.P = Movement.movementPositionP
	movementPosition.maxForce = Vector3.new()
	movementPosition.position = Vector3.new()
	Movement.movementPosition = movementPosition
	local movementVelocity = Instance.new("BodyVelocity", collider)
	movementVelocity.Name = "movementVelocity"
	movementVelocity.P = Movement.movementVelocityP
	movementVelocity.maxForce = Vector3.new()
	movementVelocity.velocity = Vector3.new()
	Movement.movementVelocity = movementVelocity
	local gravityForce = Instance.new("BodyForce", collider)
	gravityForce.Name = "gravityForce"
	gravityForce.force = Vector3.new(0, (1-Movement.gravity)*196.2, 0) * Movement:GetCharacterMass()
	Movement.gravityForce = gravityForce
end

Main()

-- [[ Some extra functions for future use ]]
--[[function Movement.GetCollisionCylinder()
	local vel = Movement.movementVelocity.Velocity
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	local TARGET_SPEED = 24
	local HIP_HEIGHT = 3.1
	local radius = math.min(2, math.max(1.5, speed/TARGET_SPEED*2))
	local biasVelicityFactor = 0.075 -- fudge constant
	local biasRadius = math.max(speed/TARGET_SPEED*2, 1)
	local biasCenter = Vector3.new(vel.X*biasVelicityFactor, 0, vel.Y*biasVelicityFactor)
	local steepestInclineAngle = math.rad(60)
	local maxInclineTan = math.tan(steepestInclineAngle)
	local maxInclineStartTan = math.tan(math.max(0, steepestInclineAngle - math.rad(2.5)))
	
	local m = Movement
	
	local onGround, groundHeight, steepness, _, normal = m.castCylinder({
		origin = m.character.PrimaryPart.Position,
		direction = Vector3.new(0, -HIP_HEIGHT*2, 0),
		steepTan = maxInclineTan,
		steepStartTan = maxInclineStartTan,
		radius = radius,
		biasCenter = biasCenter,
		biasRadius = biasRadius,
		adorns = {},
		ignoreInstance = m.character,
		hipHeight = HIP_HEIGHT,
	})
	return onGround, groundHeight, steepness, normal
end]]

--[[]]