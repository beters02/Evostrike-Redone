-- script var
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")

local sharedMovementFunctions = require(Framework.shfc_sharedMovementFunctions.Location)
local strings = require(Framework.shfc_strings.Location)
local math = require(Framework.shfc_math.Location)
local vmsprings = require(Framework.shc_vmsprings.Location)
local sharedWeaponFunctions = require(Framework.shfc_sharedWeaponFunctions.Location)
local weaponRemotes = ReplicatedStorage:WaitForChild("weapon"):WaitForChild("remote")
local reptemp = ReplicatedStorage:WaitForChild("temp")
local cameraobject = require(Framework.shc_cameraObject.Location)
local animationEventFunctions = {}
local currentPlayingWeaponSounds = {}
local connections = {}
local hotConnections = {}
local forcestop = false

-- weapon var
local tool = script.Parent.Parent
local clientModel = tool:WaitForChild("ClientModelObject").Value
local serverModel = tool.ServerModel
local weaponName = string.gsub(tool.Name, "Tool_", "")
local weaponRemoteFunction = tool:WaitForChild("WeaponRemoteFunction")
local weaponRemoteEvent = tool:WaitForChild("WeaponRemoteEvent")
local weaponGetRemote = weaponRemotes:WaitForChild("get")
local weaponObjectsFolder = tool:WaitForChild("WeaponObjectsFolderObject").Value
local weaponAnimationsFolder = weaponObjectsFolder.animations

local isKnife = true
local weaponOptions = weaponGetRemote:InvokeServer("Options", weaponName)
local weaponVar = {
	equipped = false,
	equipping = false,
	firing = false,
	reloading = false,
	currentBullet = 1,
	nextFireTime = 0,
	lastFireTime = 0,
	fireDebounce = false,
	fireLoop = false,
	fireScheduled = false,
	lastYAcc = 0,
	ammo = {
		magazine = 1,
		total = 1
	}
}
if not string.match(string.lower(tool.Name), "knife") then
	weaponVar.ammo = {
		magazine = weaponOptions.ammo.magazine,
		total = weaponOptions.ammo.total
	}
	isKnife = false
end
local weaponBar
local weaponFrame
local weaponIconEquipped
local weaponIconUnequipped
local weaponSounds
local weaponFireKeyOptName = "Key_PrimaryFire"
local weaponCameraObject = cameraobject.new(weaponName)

-- player var
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local vm = camera:WaitForChild("viewModel")
local mouse = player:GetMouse()
--local viewmodelScript
local movementScript = char:WaitForChild("movementScript")
local movementCommunicate = require(movementScript:WaitForChild("Communicate"))
local groundMaxSpeed = movementCommunicate.GetVar("groundMaxSpeed")

-- viewmodel var
local vmAnimController
local VMEquipSpring
local connectVMSpringEvent

--[[ 
    SCRIPT FUNCTIONS

    these are not kept in a FunctionContainer because almost all of
    the functions will edit the all of the script's variables.
]]

--[[@title 			- init_HUD
	
	@summary
					- Initializes the weapon frames (weapon icons) on the Main Menu HUD GUI
                    - Initializes weapon hud var

	@return			- {void}
]]

local function init_HUD()
	weaponBar = player.PlayerGui:WaitForChild("HUD").WeaponBar
	weaponFrame = weaponBar:WaitForChild(strings.firstToUpper(weaponOptions.inventorySlot))
	weaponIconEquipped = weaponFrame:WaitForChild("EquippedIconLabel")
	weaponIconUnequipped = weaponFrame:WaitForChild("UnequippedIconLabel")
	weaponIconEquipped.Image = weaponObjectsFolder.images.iconEquipped.Image
	weaponIconUnequipped.Image = weaponObjectsFolder.images.iconUnequipped.Image
	weaponFrame.Visible = true
end

--[[@title 			- init_animations
	
	@summary
					- Init all Weapon Animations for all player models including:
					- Server (humanoid), Client (viewModel)

	@return			- {void}
]]

local function init_animations()

	-- init anims table
	weaponVar.animations = {client = {}, server = {}, clienthud = {}}

	-- grab viewmodel script for animation events
	--viewmodelScript = char:WaitForChild("viewmodelScript")

	-- init client anim controller
	vmAnimController = vm.AnimationController
	--connectVMSpringEvent = viewmodelScript:WaitForChild("ConnectVMSpring")

	for _, client in pairs(weaponAnimationsFolder:GetChildren()) do

		-- init server animations
		if client.Name == "Server" then
			for _, server in pairs(client:GetChildren()) do
				weaponVar.animations.server[server.Name] = hum.Animator:LoadAnimation(server)
			end
			continue
		elseif client.ClassName ~= "Animation" then continue end
	
		-- init client animations
		weaponVar.animations.client[client.Name] = vmAnimController:LoadAnimation(client)
	end
end

--[[@title 			- init_animationEvents
	
	@summary
					- Init all Weapon Animation Event Functions for player models including:
					- Server (humanoid), Client (viewModel)

	@return			- {void}
]]

local function init_animationEvents()
	animationEventFunctions = {}

	-- [[ ANIMATION EVENT FUNCTIONS ]]

	-- viewmodel spring
	animationEventFunctions.VMSpring = function(param)
		if param == "Equip" then
			VMEquipSpring.Force = 80
			VMEquipSpring.Speed = 6
			VMEquipSpring.Damping = 2.5
			VMEquipSpring:shove(Vector3.new(-0.4, -0.4, 0))
		elseif param == "Equip3" then
			VMEquipSpring.Force = 40
			VMEquipSpring.Speed = 6
			VMEquipSpring.Damping = 4
			VMEquipSpring:shove(Vector3.zero)
		elseif param == "EquipFinal" then
			VMEquipSpring.Force = 40
			VMEquipSpring.Speed = 6
			VMEquipSpring.Damping = 2.5
			VMEquipSpring:shove(Vector3.new(math.random(20, 30) / 100, -(math.random(10,20)/100), 0))
		end
	end

	-- viewmodel spring update
	VMEquipSpring = vmsprings:new(9, 80, 4, 7)

	-- this is the update function that will be connected to the viewmodel script
	local _updateFunction = function(dt, hrp)
		local ues = VMEquipSpring:update(dt)
		return hrp.CFrame * CFrame.Angles(ues.X, ues.Y, 0)
	end

	-- this is the string that will be used to index the spring in the viewmodel script
	local springIndexStr = weaponName .. "_Equip"

	-- connect equip spring update event function to viewmodel script
	--connectVMSpringEvent:Fire(true, VMEquipSpring, springIndexStr, _updateFunction)
	
	-- weapon sounds
	weaponSounds = weaponObjectsFolder:WaitForChild("sounds")

	-- play weapon sound
	animationEventFunctions.PlaySound = function(soundName, dontDestroyOnRecreate)
		local _weaponName = weaponName
		if dontDestroyOnRecreate then _weaponName = false end

		local sound = weaponSounds:FindFirstChild(soundName)
		return sharedWeaponFunctions.PlaySound(player.Character, _weaponName, sound)
	end

	-- play replicated weapon sound (replicate to server)
	animationEventFunctions.PlayReplicatedSound = function(soundName, dontDestroyOnRecreate)
		local sound = weaponSounds:FindFirstChild(soundName)
		local _weaponName = weaponName
		if dontDestroyOnRecreate then _weaponName = false end

		-- fire event (WeaponModuleScript.server.lua) to replicate to (WeaponModuleClientScript.client.lua)
		--weaponReplicateRemote:FireServer("PlaySound", char, _weaponName, sound)

		-- play sound on local client
		sharedWeaponFunctions.PlaySound(player.Character, _weaponName, sound)
	end
	
end

--[[@title 			- util_playAnimation
	
	@summary
					- Play Weapon Animation and Connect Animation Events
                    - Will automatically disconnect upon animation length reach or animation completed
	@return			- animation: AnimationTrack
]]

function util_playAnimation(location, name)
	local animation: AnimationTrack = weaponVar.animations[location][name]

	-- connect events
	local wacvm = animation:GetMarkerReachedSignal("VMSpring"):Connect(function(param)
		animationEventFunctions.VMSpring(param)
	end)

	local wacs = animation:GetMarkerReachedSignal("PlaySound"):Connect(function(param)
		local sound: Sound = animationEventFunctions.PlaySound(param)
	end)

	animation:Play()
	task.delay(animation.Length, function()
		if animation.IsPlaying then animation.Ended:Wait() end
		wacvm:Disconnect()
		wacs:Disconnect()
	end)
	return animation
end

--[[@title 			- util_stopAllAnimations
	
	@summary
					- Stop any playing weapon animations and events
	@return			- {void}
]]

function util_stopAllAnimations()
	forcestop = true
    for _, a in pairs(weaponVar.animations) do
        for _, v in pairs(a) do
            if v.IsPlaying then v:Stop() end
        end
    end
	task.wait(0.06)
	forcestop = false
end

--[[@title 			- util_setVMTransparency
	
	@summary
					- Set viewModel and descendants to specified transparency
	@return			- {void}
]]

function util_setVMTransparency(t)
    task.spawn(function()
        for i, v in pairs(vm:GetDescendants()) do
            if v:IsA("MeshPart") or v:IsA("BasePart") then
                if v.Name == "HumanoidRootPart" or v.Name == "WeaponHandle" or v.Name == "WeaponTip" then continue end
                v.Transparency = t
            end
        end
    end)
end

--[[@title 			- util_setServerTransparency
	
	@summary
					- Sets the server's weapon model transparency. Not replicated
	@return			- {void}
]]

local disableServerTransparencyDebug = false
function util_setServerTransparency(t)
    if disableServerTransparencyDebug then return end
    for i, v in pairs(serverModel:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("MeshPart") then
			v.Transparency = 1
		end
	end
end

--[[@title 			- util_setIconEquipped
	
	@summary
					- Set the icons to equipped/unequipped
	@return			- {void}
]]

function util_setIconEquipped(equipped)
	if equipped then
		weaponIconUnequipped.Visible = false
		weaponIconEquipped.Visible = true
	else
		weaponIconUnequipped.Visible = true
		weaponIconEquipped.Visible = false
	end
end

--[[@title 			- util_processEquipAnimation
	
	@summary
					- Play the Pullout and Hold animations
	@return			- {void}
]]

function util_processEquipAnimation()

    -- enable weapon icon
	util_setIconEquipped(true)

    task.spawn(function() -- client

        -- we make the vm transparent so you cant see the animations bugging
        -- this may be unnecessary once i add seperate viewmodels to each weapon
        util_setVMTransparency(1)
        task.delay(0.07, function()
            util_setVMTransparency(0)
        end)

        -- play pullout
		local clientPullout = util_playAnimation("client", "Pullout")
		clientPullout.Stopped:Wait()
		
        -- dont play hold if not equipped or unequipping
		if forcestop then return end
        if not weaponVar.equipped and not weaponVar.equipping then return end

        -- play hold
        weaponVar.animations.client.Hold:Play()
    end)

    task.spawn(function() -- server

        local serverPullout = util_playAnimation("server", "Pullout")
        serverPullout.Stopped:Wait()

        if forcestop then return end
        if not weaponVar.equipped and not weaponVar.equipping then return end


        weaponVar.animations.server.Hold:Play()
    end)
    
end

--[[@title 			- util_fireWithChecks
	
	@summary
					- Core Fire Animation with sanity chechsk and fire debounce handling.
	@return			- {void}
]]

function util_fireWithChecks()
    if not weaponVar.equipped or weaponVar.fireDebounce or weaponVar.reloading or weaponVar.ammo.magazine <= 0 then return end

    weaponVar.fireDebounce = true

    core_fire()
    
    if weaponOptions.automatic then
        weaponVar.fireDebounce = false
    else
        conn_disableRecoilConnections(false)
    end
end

--[[@title 			- util_registerFireRayAndCameraRecoil
	
	@summary
					- 
	@return			- {void}
]]

function util_registerFireRayAndCameraRecoil()
	task.spawn(function()
		local m = player:GetMouse()
		local mray = util_getMouseTargetRayWithAcc(Vector2.new(m.X, m.Y), Vector2.zero)
		local currVecRecoil, vecmod = weaponCameraObject:getRecoilVector3(weaponCameraObject:getSprayPatternKey())
		weaponVar.currentVectorModifier = vecmod
		local acc = sharedWeaponFunctions.CalculateAccuracy(player, weaponOptions, weaponVar.currentBullet, currVecRecoil, weaponVar, char.HumanoidRootPart.Velocity.Magnitude)
		acc /= 500

		-- register client ray using client accuracy
		local direction = mray.Direction
		direction = Vector3.new(direction.X + acc.X, direction.Y + acc.Y, direction.Z).Unit

		--if weapon is a spread weapon, add inaccuracy on the X vec
		--[[if weaponOptions.spread then
			direction = Vector3.new(direction.X + acc.X, direction.Y + acc.Y, direction.Z).Unit
		else
			-- else, only add it on the Y vec (spray patterns)
			direction = Vector3.new(direction.X, direction.Y + acc.Y/500, direction.Z).Unit
		end]]

		-- get result
		local params = sharedWeaponFunctions.getFireCastParams(player, camera)
		local result = workspace:Raycast(mray.Origin, direction * 100, params)

		if result then
			-- register client shot for bullet/blood/sound effects
			sharedWeaponFunctions.RegisterShot(player, weaponOptions, result, mray.Origin)

			-- pass ray information to server for verification and damage
			local rayInformation = sharedWeaponFunctions.createRayInformation(mray, result)

			task.spawn(function()
				local hitRegistered, newAccVec = weaponRemoteFunction:InvokeServer("Fire", weaponVar.currentBullet, false, rayInformation, workspace:GetServerTimeNow())
				-- if a hit is not registered through the server, reset accuracy and attempt to register again
				--[[if not hitRegistered then
					--[[acc, weaponVar = CalculateAccuracy(weaponVar.currentBullet, currVecRecoil, weaponVar, false, newAccVec)
					local nur = GetNewTargetRay(Vector2.new(m.X, m.Y), Vector2.new(0,0))
					local direction = nur.Direction
					direction = Vector3.new(direction.X + acc.X/500, direction.Y + acc.Y/500, direction.Z).Unit
					local nr = workspace:Raycast(unitRay.Origin, direction * 100, params)
					local nri = createRayInformation(nur, nr)
					weaponRemoteFunction:InvokeServer("Fire", weaponVar.currentBullet, caccvec, nri, fireRegisterTime, true)
				end]]
			end)

			return true
		end

		-- nothing hit

		-- this shouldn't happen if the map is set
		-- up with bullet colliders surrounding the map
		return false
	end)

	-- fire camera recoil once accuracy has been calculated
	-- to avoid the bullet going where the camera recoil is
	weaponCameraObject:FireRecoil(weaponVar.currentBullet)
	
end

--[[@title 			- util_getMouseTargetRayWithAcc
	
	@summary
					- 
	@return			- {void}
]]

function util_getMouseTargetRayWithAcc(mousePos, acc)
	return camera:ScreenPointToRay(mousePos.X + -acc.X, mousePos.Y + -acc.Y)
end

--[[@title 			- util_handleHoldMovementPenalize(equip)
	
	@summary
					- 
	@return			- {void}
]]

function util_handleHoldMovementPenalize(equip)
	local currAdd = movementCommunicate.GetVar("maxSpeedAdd")

	if equip then
		currAdd -= weaponOptions.movement.penalty
	else
		currAdd += weaponOptions.movement.penalty
	end

	movementCommunicate.SetVar("maxSpeedAdd", currAdd)
	--print('set new ground max speed add', currAdd)
end

--[[@title 			- conn_enableHotConnections
	
	@summary
					- Enable connections that are to be disconnected upon unequip.
                    - Reload, Fire Connections are initialized here.
	@return			- {void}
]]

function conn_enableHotConnections()
    hotConnections.fireCheck = game:GetService("RunService").RenderStepped:Connect(function()
		local t = tick()
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			return conn_mouseDown(t)
		else
			return conn_mouseUp()
		end
	end)
	
	hotConnections.reloadCheck = UserInputService.InputBegan:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.R then
			core_reload()
		end
	end)
end

--[[@title 			- conn_disableHotConnections
	@return			- {void}
]]

function conn_disableHotConnections()
    for i, v in pairs(hotConnections) do
		v:Disconnect()
	end
end

local s = weaponOptions.inventorySlot
local tempequip = s == "primary" and "One" or s == "secondary" and "Two" or "Three"
function conn_equipInputBegan(input, gp)
    if input.KeyCode == Enum.KeyCode[tempequip] then
		if not weaponVar.equipping and not weaponVar.equipped then
			hum:EquipTool(tool)
		end
	end
end

function conn_mouseUp()
    if weaponVar.fireLoop then
        conn_disableRecoilConnections(true)
	end

	if not weaponOptions.automatic then
		if weaponVar.firing then repeat task.wait() until not weaponVar.firing end
		weaponVar.fireDebounce = false
	end
end

function conn_mouseDown(t)

    
    if weaponVar.fireScheduled then
		if t >= weaponVar.fireScheduled then
			weaponVar.fireScheduled = false
			util_fireWithChecks()
		end

        -- if there is already a fire scheduled we dont need to do anything
		return
	end

	-- fire input scheduling, it makes semi automatic weapons feel less clunky and more responsive
	if weaponVar.firing or t < weaponVar.nextFireTime then
		if not weaponVar.fireScheduled then
			local nxt = weaponVar.nextFireTime - t
			if nxt < 0.1 then
				weaponVar.fireScheduled = t + nxt
			end
		end
		return
	end

	if weaponVar.fireScheduled then return end
	util_fireWithChecks()
end

--[[@title 			- conn_disableRecoilConnections
	
	@summary
					- Disables the MouseDown FireLoop for automatic weapons.
	@return			- {void}
]]


function conn_disableRecoilConnections(isAutomatic: boolean)
    repeat task.wait() until not weaponVar.firing

    -- sanity check for mag size
    -- wait i dont get it, why "weaponVar.ammo.magazine <= 0"
    -- doesn't this cause the fire loop to continue
    -- ill leave this here incase it breaks when i remove it

    --[[if (isAutomatic and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or weaponVar.ammo.magazine <= 0) then
		return
	end]]

    if (isAutomatic and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
		return
	end

	weaponVar.fireLoop = false
end

--[[@title 			- core_equip
	
	@summary
					- Core weapon equip function
	@return			- {void}
]]


function core_equip()
    if weaponVar.equipped or weaponVar.equipping then return end
    forcestop = false
    weaponVar.equipping = true

    -- enable hot connections (fire, reload)
    task.spawn(conn_enableHotConnections)
    
    -- move model and set motors
    clientModel.Parent = vm.Equipped
    local gripParent = vm:FindFirstChild("RightArm") or vm.RightHand
    gripParent.RightGrip.Part1 = clientModel.GunComponents.WeaponHandle
    
    -- run server equip timer
    task.spawn(function()
        weaponRemoteFunction:InvokeServer("Timer", "Equip")
        if weaponVar.equipping then
            weaponVar.equipped = true
            weaponVar.equipping = false
        end
    end)

    -- animation (sounds are processed in animationevents)
    util_processEquipAnimation()

	-- set movement speed
	util_handleHoldMovementPenalize(true)
	
end

--[[@title 			- core_unequip
	@return			- {void}
]]

function core_unequip()
    clientModel.Parent = reptemp
	weaponVar.equipping = false
	weaponVar.equipped = false
    weaponVar.firing = false
    weaponVar.reloading = false
	util_handleHoldMovementPenalize(false)

    task.spawn(function()
        weaponCameraObject:StopCurrentRecoilThread()
    end)
	task.spawn(conn_disableHotConnections)
	task.spawn(util_stopAllAnimations)

    util_setIconEquipped(false)
end

--[[@title 			- core_inspect
	@return			- {void}
]]

function core_inspect()

end

--[[
	Import Core Functions based on class
]]

-- inherit some functions
local corefunc = script:FindFirstChild("corefunctions") and require(script.corefunctions) or {}
local basecorefunc = require(script:WaitForChild("basecorefunctions"))

for i, v in pairs(corefunc) do
	basecorefunc[i] = v
end

corefunc = basecorefunc
--

-- keys of functions that corefunc will use
local coreself = {
	util_registerFireRayAndCameraRecoil = util_registerFireRayAndCameraRecoil,
	util_playAnimation = util_playAnimation
}

core_fire = function()
	corefunc.fire(coreself, player, weaponOptions, weaponVar, weaponCameraObject, animationEventFunctions)
end

core_reload = function()
	corefunc.reload(weaponVar, weaponRemoteFunction)
end

--[[{                                 }]


    --      START SCRIPT        --


--[{                                 }]]

-- run all inits
init_HUD()
init_animations()
init_animationEvents()

-- connect connections
connections.equipInputBegin = UserInputService.InputBegan:Connect(conn_equipInputBegan)
connections.equip = tool.Equipped:Connect(core_equip)
connections.unequip = tool.Unequipped:Connect(core_unequip)

-- make server model invisible
util_setServerTransparency(1)