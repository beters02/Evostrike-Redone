-- script var
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local SoundModule = require(Framework.shm_sound.Location)
local States = require(Framework.shm_states.Location)
local PlayerData = require(Framework.shm_clientPlayerData.Location)

local sharedMovementFunctions = require(Framework.shfc_sharedMovementFunctions.Location)
local strings = require(Framework.shfc_strings.Location)
local Math = require(Framework.shfc_math.Location)
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
	lastYVec = 0,
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
local weaponInfoFrame
local weaponIconEquipped
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
local movementScript = char:WaitForChild("movementScript")
local movementCommunicate = require(movementScript:WaitForChild("Communicate"))
local groundMaxSpeed = movementCommunicate.GetVar("groundMaxSpeed")

-- viewmodel var
local vmAnimController
local VMEquipSpring
local connectVMSpringEvent

-- init states
States.SetStateVariable("PlayerActions", "shooting", false)
States.SetStateVariable("PlayerActions", "reloading", false)
States.SetStateVariable("PlayerActions", "weaponEquipped", false)

--[[ 
    SCRIPT FUNCTIONS

    these are not kept in a FunctionContainer because almost all of
    the functions will edit the all of the script's variables.
]]

--[[@title 			- init_keybinds
	
	@summary
					- Initializes the keybind variables for the weapon.
					- Currently it only initializes the Equip key.

	@return			- {void}
]]

local function init_keybinds()

	-- init key path
	weaponVar._keypath = "options.keybinds." .. weaponOptions.inventorySlot .. "Weapon"

	-- when a key is changed from the data, we will fire a
	-- bindable event to let the client know to update the HUD
	weaponVar._keyChangedBind = Instance.new("BindableEvent", tool)
	weaponVar._keyChangedBind.Name = "KeyChangedBindableEvent"

	-- connect playerdata changed
	PlayerData:Changed(weaponVar._keypath, function(newValue)
		weaponVar._equipKey = weaponVar._convert(newValue)
		weaponVar._keyChangedBind:Fire(newValue)
	end)

	-- init key
	weaponVar._equipKey = PlayerData:Get(weaponVar._keypath)

end

--[[@title 			- init_HUD
	
	@summary
					- Initializes the weapon frames (weapon icons) on the Main Menu HUD GUI
                    - Initializes weapon hud var

	@return			- {void}
]]

local function init_HUD()

	
	-- init weapon bar
	weaponBar = player.PlayerGui:WaitForChild("HUD").WeaponBar
	weaponFrame = weaponBar:WaitForChild(strings.firstToUpper(weaponOptions.inventorySlot))
	weaponInfoFrame = player.PlayerGui.HUD.InfoCanvas.MainFrame.WeaponFrame
	weaponVar.infoFrame = weaponInfoFrame

	-- init icons
	weaponIconEquipped = weaponFrame:WaitForChild("EquippedIconLabel")
	weaponIconEquipped.Image = weaponObjectsFolder.images.iconEquipped.Image
	util_setIconEquipped(false)

	-- key
	weaponBar.SideBar[weaponOptions.inventorySlot .. "Key"].Text = strings.convertFullNumberStringToNumberString(weaponVar._equipKey)

	-- connect key changed bind for hud elements
	weaponVar._keyChangedBind.Event:Connect(function(newValue)
		weaponBar.SideBar[weaponOptions.inventorySlot .. "Key"].Text = strings.convertFullNumberStringToNumberString(newValue)
	end)

	-- disable weaponFrame on death
	game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathBE").Event:Once(function()
		weaponFrame.Visible = false
	end)

	-- enable
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
		--[[if not VMEquipSpring then return end
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
		end]]
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
		SoundModule.PlayReplicatedClone(sound, player.Character.HumanoidRootPart)
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
                if v.Name == "HumanoidRootPart" or v.Name == "WeaponHandle" or v.Name == "WeaponTip" or v:GetAttribute("IgnoreTransparency") then continue end
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

function util_setServerTransparency(t)
    for i, v in pairs(serverModel:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("MeshPart") then
			v.Transparency = t
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
		weaponIconEquipped.ImageColor3 = weaponIconEquipped.Parent:GetAttribute("EquippedColor")
	else
		weaponIconEquipped.ImageColor3 = weaponIconEquipped.Parent:GetAttribute("UnequippedColor")
	end
end

--[[@title 			- util_processEquipAnimation
	
	@summary
					- Play the Pullout and Hold animations
	@return			- {void}
]]

function util_processEquipAnimation()

	util_setVMTransparency(1)

	-- disable grenade throwing animation if neccessary
	task.spawn(function()
		local _throwing = States.GetStateVariable("PlayerActions", "grenadeThrowing")
		if _throwing then
			print(_throwing)
			-- find ability folder on character
			if not player.Character:FindFirstChild("AbilityFolder_" .. _throwing) then warn("Could not cancel ability throw anim! Couldnt find ability folder") return end
			player.Character["AbilityFolder_" .. _throwing].Scripts.base_client.communicate:Fire("StopThrowAnimation")
		end
	end)

    task.spawn(function() -- client

        -- we make the vm transparent so you cant see the animations bugging
        -- this may be unnecessary once i add seperate viewmodels to each weapon
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

	-- reset origin point if currBullet is 1
	if weaponVar.currentBullet == 1 then
		util_resetSprayOriginPoint()
	end

    core_fire()
	
    
    if weaponOptions.automatic then
        weaponVar.fireDebounce = false
    else
        conn_disableRecoilConnections(false)
    end
end

--[[@title 			- util_RegisterRecoils
	
	@summary
					- registerFireRayAndCameraRecoil
	@return			- {void}
]]

function util_RegisterRecoils()

	-- Vector Recoil
	task.spawn(function()

		-- grab vector recoil from pattern using the camera object
		local m = player:GetMouse()
		local mray = util_getMouseTargetRayWithAcc(Vector2.new(m.X, m.Y), Vector2.zero)
		local currVecRecoil, vecmod, camRecoil = weaponCameraObject:getRecoilVector3(weaponCameraObject:getSprayPatternKey())
		weaponVar.currentVectorModifier = vecmod

		-- recalculate mray direction to be the height of origin point
		-- the origin point will be reset in conn_mouseUp
		if not weaponVar.originPoint then
			weaponVar.originPoint = {Direction = mray.Direction, Origin = mray.Origin}
		end

		mray = {Direction = mray.Direction, Origin = mray.Origin}
		mray.Direction = Vector3.new(
			mray.Direction.X,
			--(weaponVar.originPoint.Direction.Y + mray.Direction.Y)/2 - math.min(camRecoil.X/12, weaponOptions.fireVectorCameraMax.X),
			--(weaponVar.originPoint.Direction.Y + mray.Direction.Y)/2 + (weaponVar.totalRecoiledVector.Y/12),
			--mray.Direction.Y - math.min(camRecoil.X/12, weaponOptions.fireVectorCameraMax.X),
			mray.Direction.Y,
			mray.Direction.Z
		)

		-- get total accuracy and recoil vec direction
		local direction = sharedWeaponFunctions.GetAccuracyAndRecoilDirection(player, mray, currVecRecoil, weaponOptions, weaponVar)

		-- get ray params & fire ray
		local params = sharedWeaponFunctions.getFireCastParams(player, camera)
		local result = workspace:Raycast(mray.Origin, direction * 250, params)

		if result then

			-- register client shot for bullet/blood/sound effects
			sharedWeaponFunctions.RegisterShot(player, weaponOptions, result, mray.Origin)

			-- pass ray information to server for verification and damage
			task.spawn(function()
				local hitRegistered, newAccVec = weaponRemoteFunction:InvokeServer("Fire", weaponVar.currentBullet, false, sharedWeaponFunctions.createRayInformation(mray, result), workspace:GetServerTimeNow())
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

--[[@title 			- util_resetSprayOriginPoint
	
	@summary
					- 
	@return			- {void}
]]

function util_resetSprayOriginPoint()
	weaponVar.originPoint = nil
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

--[[@title 			- util_setInfoFrameWeapon()
	
	@summary
					- 
	@return			- {void}
]]

function util_setInfoFrameWeapon()
	weaponInfoFrame.KnifeNameLabel.Visible = false
	weaponInfoFrame.GunNameLabel.Visible = true
	weaponInfoFrame.CurrentMagLabel.Visible = true
	weaponInfoFrame.CurrentTotalAmmoLabel.Visible = true
	weaponInfoFrame["/"].Visible = true
	weaponInfoFrame.CurrentMagLabel.Text = tostring(weaponVar.ammo.magazine)
	weaponInfoFrame.CurrentTotalAmmoLabel.Text = tostring(weaponVar.ammo.total)
	weaponInfoFrame.GunNameLabel.Text = strings.firstToUpper(weaponName)
end

--[[@title 			- util_setInfoFrameKnife()
	
	@summary
					- 
	@return			- {void}
]]

function util_setInfoFrameKnife()
	weaponInfoFrame.KnifeNameLabel.Visible = true
	weaponInfoFrame.GunNameLabel.Visible = false
	weaponInfoFrame.CurrentMagLabel.Visible = false
	weaponInfoFrame.CurrentTotalAmmoLabel.Visible = false
	weaponInfoFrame["/"].Visible = false
end

--[[@title 			- conn_enableHotConnections
	
	@summary
					- Enable connections that are to be disconnected upon unequip.
                    - Reload, Fire Connections are initialized here.
	@return			- {void}
]]

function conn_enableHotConnections()
    --hotConnections.fireCheck = game:GetService("RunService").RenderStepped:Connect(fireCheck)
	
	--[[hotConnections.reloadCheck = UserInputService.InputBegan:Connect(function(input, gp)
		if not player.Character or hum.Health <= 0 then return end
		if input.KeyCode == Enum.KeyCode.R then
			core_reload()
		end
	end)]]
end

function fireCheck()
	if not player.Character or hum.Health <= 0 then return end
	local t = tick()
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		return conn_mouseDown(t)
	else
		return conn_mouseUp()
	end
end

--[[@title 			- conn_disableHotConnections
	@return			- {void}
]]

function conn_disableHotConnections()
    for i, v in pairs(hotConnections) do
		v:Disconnect()
	end
end

function conn_equipInputBegan(input, gp)
	if not player.Character or hum.Health <= 0 then return end

    if input.KeyCode == Enum.KeyCode[weaponVar._equipKey] then
		if not weaponVar.equipping and not weaponVar.equipped then
			hum:EquipTool(tool)
		end
	end
end

function conn_mouseUp()
	if not player.Character or hum.Health <= 0 then return end
    if weaponVar.fireLoop then
        conn_disableRecoilConnections(true)
	end

	if not weaponOptions.automatic then
		--if weaponVar.firing then repeat task.wait() until not weaponVar.firing end
		weaponVar.fireDebounce = false
		util_resetSprayOriginPoint()
	end
end

function conn_mouseDown(t)
	if not player.Character or hum.Health <= 0 then return end
	t = type(t) == "number" and t or tick()
    
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
			if nxt < 0.2 then
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

local m_inputs = require(player.PlayerScripts.m_inputs)
local bind = m_inputs._bindModule

function binds_connectHotBinds()
	if not weaponVar._hotBinds then weaponVar._hotBinds = {} end

	local hotHeyProp: bind.KeyActionProperties = {
		Repeats = false,
		IgnoreOnDead = true,
		IgnoreWhen = {
			function() return not weaponVar.equipped end
		}
	}

	local fireKeyProp: bind.KeyActionProperties = {
		Repeats = weaponOptions.automatic,
		RepeatDelay = 0,
		IgnoreOnDead = true,
		IgnoreWhen = {
			function() return not weaponVar.equipped end
		}
	}
	
	weaponVar._hotBinds.reload = m_inputs:Bind(
		"R",
		weaponName .. "_Reload",
		hotHeyProp,
		{},
		core_reload
	):: bind.KeyAction

	weaponVar._hotBinds.fire = m_inputs:Bind(
		"MouseButton1",
		weaponName .. "_Fire",
		fireKeyProp,
		{},
		conn_mouseDown,
		conn_mouseUp
	):: bind.KeyAction

end

function binds_disconnectHotBinds()
	if not weaponVar._hotBinds then return end

	for i, v in pairs(weaponVar._hotBinds) do
		v.Unbind()
	end

	weaponVar._hotBinds = {}
end

function core_equip()
	util_resetSprayOriginPoint()
    forcestop = false
    weaponVar.equipping = true
	States.SetStateVariable("PlayerActions", "weaponEquipping", true)
	States.SetStateVariable("PlayerActions", "weaponEquipped", weaponName)

    -- enable hot connections (fire, reload)
    task.spawn(conn_enableHotConnections)
	task.spawn(binds_connectHotBinds)

	-- enable weapon icon
	util_setIconEquipped(true)
    
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
			States.SetStateVariable("PlayerActions", "weaponEquipping", false)
        end
    end)

	-- HUD and Sound
	if weaponOptions.inventorySlot == "ternary" then -- knife
		animationEventFunctions.PlayReplicatedSound("Equip") -- equip sound
		util_setInfoFrameKnife()
	else -- weapon
		-- equip sound is played via animation events for weapons
		util_setInfoFrameWeapon()
	end

    -- animation (sounds are processed in animationevents)
    util_processEquipAnimation()

	-- set movement speed
	util_handleHoldMovementPenalize(true)
end

--[[@title 			- core_unequip
	@return			- {void}
]]

function core_unequip()
	if not player.Character or hum.Health <= 0 then return end
    clientModel.Parent = reptemp
	weaponVar.equipping = false
	weaponVar.equipped = false
    weaponVar.firing = false
    weaponVar.reloading = false
	States.SetStateVariable("PlayerActions", "weaponEquipped", false)
	States.SetStateVariable("PlayerActions", "weaponEquipping", false)
	States.SetStateVariable("PlayerActions", "reloading", false)
	States.SetStateVariable("PlayerActions", "shooting", false)
	util_handleHoldMovementPenalize(false)
	util_resetSprayOriginPoint()
	util_setVMTransparency(1)

    task.spawn(function()
        weaponCameraObject:StopCurrentRecoilThread()
    end)
	task.spawn(conn_disableHotConnections)
	task.spawn(binds_disconnectHotBinds)
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
	util_RegisterRecoils = util_RegisterRecoils,
	util_playAnimation = util_playAnimation
}

core_fire = function()
	if not player.Character or hum.Health <= 0 then return end
	if States.GetStateVariable("PlayerActions", "grenadeThrowing") then return end
	local autoReload
	weaponVar, autoReload = corefunc.fire(coreself, player, weaponOptions, weaponVar, weaponCameraObject, animationEventFunctions)
	if autoReload then
		task.spawn(function()
			repeat task.wait() until tick() >= autoReload
			core_reload()
		end)
	end
end

core_reload = function()
	if not player.Character or hum.Health <= 0 then return end
	if States.GetStateVariable("PlayerActions", "grenadeThrowing") then return end
	weaponVar = corefunc.reload(weaponOptions, weaponVar, weaponRemoteFunction)
end


--[[{                                 }]


    --      START SCRIPT        --


--[{                                 }]]

-- run all inits
init_keybinds()
init_HUD()
init_animations()
init_animationEvents()

-- connect connections
connections.equipInputBegin = UserInputService.InputBegan:Connect(conn_equipInputBegan)
connections.equip = tool.Equipped:Connect(core_equip)
connections.unequip = tool.Unequipped:Connect(core_unequip)

-- make server model invisible
local debugServerModel = false
if debugServerModel then
	util_setServerTransparency(0)
else
	util_setServerTransparency(1)
end