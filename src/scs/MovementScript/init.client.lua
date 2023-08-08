--[[ TODO ]]
--[[

	- Add particles for walking/landing/dashing

]]

-- [[ Services ]]
local Players = game:GetService("Players")
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService("RunService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))

-- [[ Define Local Variables ]]
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

local playerGrounded = false
local playerVelocity = Vector3.zero
local jumping = false
local jumpCooldown = false
local inAir = false
local landing = false

local landed = Events:WaitForChild("Landed")
local movementState = require(Framework.ReplicatedStorage.Modules:WaitForChild("States")).Movement

local hudCharModule = require(Framework.ReplicatedStorage.Libraries.HUDCharacter)
local hudCharClass = hudCharModule.GetHUDCharacter()
if typeof(hudCharClass) == "RBXScriptSignal" then hudCharClass = hudCharClass:Wait() end
if not hudCharClass then warn("Couldn't load Movement HUDCharacter animations!") end

local runningAnimation = hum.Animator:LoadAnimation(hum.Animations.Run)
local jumpingAnimation = hum.Animator:LoadAnimation(hum.Animations.Jump)
local hcRunningAnimation = hudCharClass.LoadAnimation(hum.Animations.Run)
local hcJumpingAnimation = hudCharClass.LoadAnimation(hum.Animations.Jump)

--[[ 
	Variables for Custom Movement Abilities
]]
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
	humanoid = character:WaitForChild("Humanoid"),
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

	dashing = false
	
}
Movement.__index = Movement

-- init sounds
local humSounds = Movement.humanoid:WaitForChild("Sounds")
local runsndsF = humSounds:WaitForChild("Run")
local runsnds = {}
for _, s in pairs(runsndsF:GetChildren()) do
	if not s:IsA("Sound") then continue end
	runsnds[s.Name] = s
end

-- init HUD character
hudCharClass.animations = {running = hudCharClass.LoadAnimation(hum.Animations.Run), jumping = hudCharClass.LoadAnimation(hum.Animations.Jump)}

Movement.Sounds = {
	runDefault = runsnds.Tile,
	landDefault = runsnds.Tile:Clone()
}
Movement.Sounds.landDefault.Parent = humSounds
local runv = Movement.Sounds.runDefault.Volume

function Movement.GetIgnoreDescendantInstances()
	return {character, workspace.CurrentCamera, workspace.Temp, workspace.MovementIgnore}
end

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
	Movement:ApplyAirVelocity()
	Movement.movementVelocity.maxForce = Movement:GetMovementVelocityAirForce()
	local runsnd = Movement.Sounds.runDefault
	if runsnd.IsPlaying then runsnd:Stop() end
end

--[[
	@title  		- Movement.Run

	@summary
]]

function Movement.Run(hitPosition)
	Movement.movementPosition.position = hitPosition + Vector3.new(0, Movement.playerTorsoToGround, 0)
	Movement.movementPosition.maxForce = Vector3.new(0, Movement.movementPositionForce, 0)
	Movement:ApplyGroundVelocity()
	Movement.movementVelocity.maxForce = Movement:GetMovementVelocityForce()
	Movement.movementVelocity.P = Movement.movementVelocityP

	-- get current run sound
	-- TODO: groundcast for result material
	local runsnd = Movement.Sounds.runDefault
	local jumpsnd
	local landsnd = Movement.Sounds.landDefault

	if jumpingAnimation.IsPlaying then
		jumpingAnimation:Stop(0.1)
	end

	if hudCharClass.animations.jumping.IsPlaying then
		hudCharClass.animations.jumping:Stop(0.1)
	end

	if Movement.movementVelocity.Velocity.Magnitude > 1 then
		if not runningAnimation.IsPlaying then runningAnimation:Play(0.2) end
		if not hudCharClass.animations.running.isPlaying then hudCharClass.animations.running:Play(0.2) end
		if not runsnd.IsPlaying then runsnd:Play() end
	else
		if runningAnimation.IsPlaying then runningAnimation:Stop(0.2) end
		if hudCharClass.animations.running.isPlaying then hudCharClass.animations.running:Stop(0.2) end
		if runsnd.IsPlaying then runsnd:Stop() end
	end
end

--[[
	@title  		- Movement.Jump

	@summary
]]

local connectViewmodelJump = true
local vmScript

function Movement.Jump(velocity)
	Movement.jumpGrace = tick() + Movement.jumpTimeBeforeGroundRegister -- This is how i saved the glitchy mousewheel jump
	collider.Velocity = Vector3.new(collider.Velocity.X, velocity, collider.Velocity.Z)
	Movement.Air()

	if hudCharClass.animations.running.isPlaying then hudCharClass.animations.running:Stop(0.2) end
	if runningAnimation.IsPlaying then runningAnimation:Stop(0.1) end

	hudCharClass.animations.jumping:Play(0.1)

	if connectViewmodelJump then
		if not vmScript then vmScript = character.ViewmodelScript end
		vmScript.Jump:Fire()
	end

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
	--TODO: play land sound
	local landsnd = Movement.Sounds.landDefault
	local runsnd = Movement.Sounds.runDefault
	runsnd.Volume = 0
	if landsnd.IsPlaying then landsnd:Stop() end
	landsnd:Play()
	task.delay(0.1, function()
		landsnd:Stop()
		runsnd.Volume = runv
	end)

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

	-- iterate
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
	dashVariables.direction = collider.CFrame.LookVector

	if currentInputSum.Forward == 0 and currentInputSum.Side == 0 then
	else
		local fordir = currentInputSum.Forward ~= 0 and (currentInputSum.Forward > 0 and collider.CFrame.LookVector or -collider.CFrame.LookVector) or 1
		local sidedir = currentInputSum.Side ~= 0 and (currentInputSum.Side > 0 and -collider.CFrame.RightVector or collider.CFrame.RightVector) or 1

		dashVariables.direction = (fordir * sidedir).Unit		
	end
	print(dashVariables.direction)
	dashVariables.trigger = true
end

function Movement.Dash()
	Movement.dashing = true
	
	if playerGrounded then
		Movement.Jump(dashVariables.upstrength)
	end

	task.wait()
	
	local newVel = (dashVariables.direction * dashVariables.strength)
	Movement.movementVelocity.Velocity = Vector3.new(newVel.X, Movement.movementVelocity.Velocity.Y, newVel.Z)

	Movement.Air()
	
	playerGrounded = false
	inAir = tick()
	
	task.wait(0.01)
	
	landed.Event:Wait()
	Movement.dashing = false
	Movement.Land(0.6)
end

--[[
	Processing
]]

function Movement.ProcessMovement()
	cameraYaw = Movement:GetYaw()
	cameraLook = cameraYaw.lookVector
	Movement.cameraYaw = cameraYaw
	Movement.cameraLook = cameraLook
	
	if cameraLook == nil then return end
	
	local currVel = Movement.movementVelocity.Velocity
	if currVel.X ~= currVel.X then Movement.movementVelocity.Velocity = Vector3.new(0,0,0)
	elseif currVel.Y ~= currVel.Y then Movement.movementVelocity.Velocity = Vector3.new(0,0,0)
	elseif currVel.Z ~= currVel.Z then Movement.movementVelocity.Velocity = Vector3.new(0,0,0) end

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
		--return
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
	if playerGrounded and not Movement.dashing then
		if jumping then
			-- call ground movement if on jump cooldown and trying to jump
			if jumpCooldown or inAir then
				Movement.Run(hitPosition)
			else
				--print('jumping')
				-- [[ JUMP MOVEMENT ]]
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
	Movement.currentInputSum = currentInputSum
end

--[[
	Main Scope
]]
local prevUpdateTime = nil
local updateDT = 1/60
local inAirMovementState = false

function Update(dt)
	if not hum or (hum and hum.Health <= 0) then return end
	currentDT = dt
	Movement.currentDT = dt

	Inputs.UpdateMovementSum()
	Movement.ProcessMovement()
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

	-- connect script connections
	UserInputService.InputBegan:Connect(Inputs.OnInput)
	UserInputService.InputEnded:Connect(Inputs.OnInput)
	UserInputService.InputChanged:Connect(Inputs.OnInputChange)
	RunService:BindToRenderStep("updateLoop", 100, UpdateLoop)

	-- connect movement abilities
	script.Events.Dash.Event:Connect(Movement.RegisterDashVariables)

	script.Events.Get.OnInvoke = function()
		return playerGrounded
	end
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