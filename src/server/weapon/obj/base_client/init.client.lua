-- script var
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local SoundModule = require(Framework.shm_sound.Location)
local States = require(Framework.shm_states.Location)
local PlayerData = require(Framework.shm_clientPlayerData.Location)
local RaycastHitbox = require(Framework.Module.lib.c_raycasthitbox)

local strings = require(Framework.shfc_strings.Location)
local vmsprings = require(Framework.shc_vmsprings.Location)
local sharedWeaponFunctions = require(Framework.shfc_sharedWeaponFunctions.Location)
local weaponRemotes = ReplicatedStorage:WaitForChild("weapon"):WaitForChild("remote")
local reptemp = ReplicatedStorage:WaitForChild("temp")
local cameraobject = require(Framework.shc_cameraObject.Location)
local animationEventFunctions = {}
local connections = {}
local coreself = {}
local hotVariables = {mouseDown = false}
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
	},
	serverModel = serverModel,
	clientModel = clientModel
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
local weaponWallbangInformation = weaponGetRemote:InvokeServer("WallbangMaterials")
-- player var
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local vm = camera:WaitForChild("viewModel")
local mouse = player:GetMouse()
local movementScript = char:WaitForChild("MovementScript")
local movementCommunicate = require(movementScript:WaitForChild("Communicate"))
local groundMaxSpeed = movementCommunicate.GetVar("groundMaxSpeed")

-- viewmodel var
local vmAnimController
local VMEquipSpring
local connectVMSpringEvent

local defGroundMaxSpeed

-- get controller
local weaponController2 = require(char:WaitForChild("WeaponController").Interface)

-- init states
States.SetStateVariable("PlayerActions", "shooting", false)
States.SetStateVariable("PlayerActions", "reloading", false)
States.SetStateVariable("PlayerActions", "weaponEquipped", false)

--[[ 
    SCRIPT FUNCTIONS

    these are not kept in a FunctionContainer because almost all of
    the functions will edit the all of the script's variables.
]]

local function init_variables()
	defGroundMaxSpeed = movementCommunicate.GetVar("groundMaxSpeed")
end

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
		weaponVar._equipKey = newValue
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
	animationEventFunctions.PlaySound = function(soundName, dontDestroyOnRecreate, isReplicated)
		local _weaponName = weaponName
		if dontDestroyOnRecreate then _weaponName = false end
		local sound = weaponSounds:FindFirstChild(soundName)
		if not sound then return end

		if sound:IsA("Folder") then
			for _, v in pairs(sound:GetChildren()) do
				task.spawn(function()
					if isReplicated then
						SoundModule.PlayReplicatedClone(v, player.Character.HumanoidRootPart, true)
					else
						sharedWeaponFunctions.PlaySound(player.Character, _weaponName, v)
					end
				end)
			end
			return
		end

		if isReplicated then
			return SoundModule.PlayReplicatedClone(sound, player.Character.HumanoidRootPart, true)
		else
			return sharedWeaponFunctions.PlaySound(player.Character, _weaponName, sound)
		end
	end

	-- play replicated weapon sound (replicate to server)
	animationEventFunctions.PlayReplicatedSound = function(soundName, dontDestroyOnRecreate)
		animationEventFunctions.PlaySound(soundName, dontDestroyOnRecreate, true)
	end

	coreself.animationEventFunctions = animationEventFunctions
end

-- init knife's extra variables and functiolity
local function init_knife()
	weaponVar._raycastHitbox = RaycastHitbox.new(clientModel:FindFirstChild("Blade") or clientModel)
	weaponVar._raycastHitbox.Visualizer = false
	weaponVar._raycastHitbox:SetPoints(clientModel.GunComponents.WeaponHandle, {Vector3.new(1, 0, 0), Vector3.new(5, 0, 0), Vector3.new(10, 0, 0)})
	weaponVar._knifeParams = RaycastParams.new()
	weaponVar._knifeParams.CollisionGroup = "Bullets"
	weaponVar._knifeParams.FilterDescendantsInstances = {player.Character, workspace.CurrentCamera}
	weaponVar._knifeParams.FilterType = Enum.RaycastFilterType.Exclude
end

local function init_weaponControllerWeapon()
	if not weaponController2.CurrentController then
		local t = tick() + 3
		repeat task.wait() until weaponController2.CurrentController or tick() >= t
		if not weaponController2.CurrentController then
			error("Could not initialize WeaponController Weapon, No Weapon Controller found.")
		end
	end

	local _actionFunctions = {
		firedown 				= function() return conn_mouseDown(tick()) end,
		secondaryfiredown 		= function() return conn_mouseDown(tick(), true) end,
		fireup 					= function() return conn_mouseUp() end,
		startinspect			= core_inspect,
		stopinspect				= core_stopInspecting,
		reload					= core_reload,
		remoteEvent				= weaponRemoteEvent
	}

	weaponController2.CurrentController:AddWeapon(weaponName, weaponOptions, false, tool, clientModel, tool:GetAttribute("IsForceEquip"), _actionFunctions)
end

--[[@title 			- util_playAnimation
	
	@summary
					- Play Weapon Animation and Connect Animation Events
                    - Will automatically disconnect upon animation length reach or animation completed
	@return			- animation: AnimationTrack
]]

function util_playAnimation(location: "client"|"server", name: string, fadeIn: number?, cancelOtherActionAnimations: boolean?, cancelFadeOut: number?)
	local animation: AnimationTrack = weaponVar.animations[location][name]

	-- connect events
	local wacvm = animation:GetMarkerReachedSignal("VMSpring"):Connect(function(param)
		animationEventFunctions.VMSpring(param)
	end)

	local wacs = animation:GetMarkerReachedSignal("PlaySound"):Connect(function(param)
		animationEventFunctions.PlaySound(param)
	end)

	local wacrs = animation:GetMarkerReachedSignal("PlayReplicatedSound"):Connect(function(param)
		animationEventFunctions.PlayReplicatedSound(param)
	end)

	if cancelOtherActionAnimations then
		task.spawn(function()
			
		end)
		util_stopAllLocalAnimationsExceptHold(cancelFadeOut or nil, {name = true})
	end

	animation:Play(fadeIn or nil)
	animation.Stopped:Once(function()
		wacvm:Disconnect()
		wacs:Disconnect()
		wacrs:Disconnect()
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

	-- stop client first
	for _, a in pairs(weaponVar.animations.client) do
		a:Stop()
	end

	for _, a in pairs(weaponVar.animations.server) do
		a:Stop()
	end

	task.wait(0.06)
	forcestop = false
end

function util_stopAllVMAnimations()
	for _, v in pairs(vmAnimController:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end

function util_stopAllLocalAnimationsExceptHold(fadeOut, except) -- except = {animName = true}
	for _, a in pairs(weaponVar.animations.client) do
		if a.Name == "Hold" then continue end
		if except and except[a.Name] then continue end
		a:Stop(fadeOut)
	end
end

--[[@title 			- util_setServerTransparency
	
	@summary
					- Sets the server's weapon model transparency. Not replicated
	@return			- {void}
]]

function util_setServerTransparency(t)
    for i, v in pairs(serverModel:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Texture") then
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
	util_stopAllVMAnimations()
	
	-- disable grenade throwing animation if neccessary
	task.spawn(function()
		local _throwing = States.GetStateVariable("PlayerActions", "grenadeThrowing")
		if _throwing then
			-- find ability folder on character
			if not player.Character:FindFirstChild("AbilityFolder_" .. _throwing) then warn("Could not cancel ability throw anim! Couldnt find ability folder") return end
			player.Character["AbilityFolder_" .. _throwing].Scripts.base_client.communicate:Fire("StopThrowAnimation")
		end
	end)

    task.spawn(function() -- client

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

function util_fireWithChecks(t, isSecondaryFire)
    if not weaponVar.equipped or weaponVar.fireDebounce or weaponVar.reloading or weaponVar.ammo.magazine <= 0 then return end
	if not hotVariables.mouseDown then return end
    weaponVar.fireDebounce = true

	-- reset origin point if currBullet is 1
	if weaponVar.currentBullet == 1 then
		util_resetSprayOriginPoint()
	end

	if isSecondaryFire then
		core_secondaryFire()
	else
		core_fire(t)
	end
    
    
    if weaponOptions.automatic then
        weaponVar.fireDebounce = false
    else
        conn_disableRecoilConnections(false)
    end
end

--@return damageMultiplier (total damage reduction added up from recursion)
function util_ShootWallRayRecurse(origin, direction, params, hitPart, damageMultiplier, filter)

	if not filter then filter = params.FilterDescendantsInstances end

	local _p = RaycastParams.new()
	_p.CollisionGroup = "Bullets"
	_p.FilterDescendantsInstances = filter
	_p.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, direction, _p)
	if not result then warn("No wallbang result but player result") return false end

	local hitchar = result.Instance:FindFirstAncestorWhichIsA("Model")
	if hitchar and hitchar:FindFirstChild("Humanoid") then
		return damageMultiplier, result, hitchar
	end

	local bangableMaterial = result.Instance:GetAttribute("Bangable") or hitchar:GetAttribute("Bangable")
	if not bangableMaterial then return false, result end

	for _, v in pairs(filter) do
		if result.Instance == v then warn("Saved you from a life of hell my friend") return false end
	end

	-- create bullethole at wall
	sharedWeaponFunctions.RegisterShot(player, weaponOptions, result, origin, nil, nil, nil, nil, true, tool, clientModel)

	table.insert(filter, result.Instance)
	return util_ShootWallRayRecurse(origin, direction, _p, result.Instance, (damageMultiplier + weaponWallbangInformation[bangableMaterial])/2, filter)
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
			mray.Direction.Y,
			mray.Direction.Z
		)

		--[[
			--(weaponVar.originPoint.Direction.Y + mray.Direction.Y)/2 - math.min(camRecoil.X/12, weaponOptions.fireVectorCameraMax.X),
			--(weaponVar.originPoint.Direction.Y + mray.Direction.Y)/2 + (weaponVar.totalRecoiledVector.Y/12),
			--mray.Direction.Y - math.min(camRecoil.X/12, weaponOptions.fireVectorCameraMax.X),
		]]

		-- get total accuracy and recoil vec direction
		local direction = sharedWeaponFunctions.GetAccuracyAndRecoilDirection(player, mray, currVecRecoil, weaponOptions, weaponVar)

		-- check to see if we're wallbanging
		local wallDmgMult, hitchar, result
		local normParams = sharedWeaponFunctions.getFireCastParams(player, camera)
		wallDmgMult, result, hitchar = util_ShootWallRayRecurse(mray.Origin, direction * 250, normParams, nil, 1)

		if result then

			--print(result)

			-- register client shot for bullet/blood/sound effects
			sharedWeaponFunctions.RegisterShot(player, weaponOptions, result, mray.Origin, nil, nil, hitchar, wallDmgMult or 1, wallDmgMult and true or false, tool, clientModel)

			-- pass ray information to server for verification and damage
			weaponRemoteEvent:FireServer("Fire", weaponVar.currentBullet, false, sharedWeaponFunctions.createRayInformation(mray, result), workspace:GetServerTimeNow(), wallDmgMult)
			--weaponRemoteFunction:InvokeServer("Fire", weaponVar.currentBullet, false, sharedWeaponFunctions.createRayInformation(mray, result), workspace:GetServerTimeNow(), wallDmgMult)
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

local Restrictions = require(movementScript.Restrictions)

function util_handleHoldMovementPenalize(equip)
	task.wait()
	local currAdd = movementCommunicate.GetVar("maxSpeedAdd")

	--local currAdd = Restrictions:Set

	-- Resolve: players spawning with hella crazy speed
	-- sanity (currAdd should always be negative)
	if currAdd + defGroundMaxSpeed > defGroundMaxSpeed then
		currAdd = 0
	end

	if equip then
		currAdd -= weaponOptions.movement.penalty
	else
		currAdd += weaponOptions.movement.penalty
	end

	movementCommunicate.SetVar("maxSpeedAdd", currAdd)
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
	print('wepset')
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
	print('kset')
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

function conn_mouseUp(forceCancel)
	if not player.Character or hum.Health <= 0 then return end
	hotVariables.mouseDown = false

	if weaponVar.fireScheduled then
		if forceCancel then
			coroutine.yield(weaponVar.fireScheduled)
			weaponVar.fireScheduled = nil
		else
			-- cancel fire scheduled after a full 64 tick of mouse being up
			hotVariables.fireScheduleCancelThread = task.delay(1/64, function()
				if weaponVar.fireScheduled and not weaponVar.mouseDown and weaponVar.firing then
					coroutine.yield(weaponVar.fireScheduled)
					weaponVar.fireScheduled = nil
				end
				coroutine.yield(hotVariables.fireScheduleCancelThread)
				hotVariables.fireScheduleCancelThread = nil
			end)
		end
	end

    if weaponVar.fireLoop then
        conn_disableRecoilConnections(true)
	end

	if not weaponOptions.automatic then
		weaponVar.fireDebounce = false
		util_resetSprayOriginPoint()
	end

end

function conn_mouseDown(t, secondaryMouse)
	if not player.Character or hum.Health <= 0 then return end
	local fireRate = weaponOptions.fireRate
	print('yah')

	if secondaryMouse then
		if string.lower(weaponName) ~= "knife" then
			warn('asdasd')
			return
		end
		fireRate = weaponOptions.secondaryFireRate
	end

	t = type(t) == "number" and t or tick()

	hotVariables.mouseDown = true

	if not weaponOptions.automatic then

		-- fire input scheduling, it makes semi automatic weapons feel less clunky and more responsive
		if hotVariables.fireScheduleCancelThread then
			coroutine.yield(hotVariables.fireScheduleCancelThread)
			hotVariables.fireScheduleCancelThread = nil
		end
	
		if weaponVar.fireScheduled then
			return
		end

		if weaponVar.firing then
			weaponVar.fireScheduled = task.spawn(function()
				repeat task.wait() until not weaponVar.firing
				util_fireWithChecks(tick(), secondaryMouse)
				weaponVar.fireScheduled = nil
				hotVariables.fireScheduleCancelThread = nil
			end)
			return
		end

		util_fireWithChecks(t, secondaryMouse)
	
	else

	if not weaponVar.accumulator then weaponVar.accumulator = 0 end
	
		if not weaponVar.fireLoop then

			-- register initial fire boolean
			local startWithInit = false

			if tick() >= weaponVar.nextFireTime then
				startWithInit = true
				weaponVar.nextFireTime = tick() + fireRate -- set next fire time
				weaponVar.accumulator = 0
			else
				weaponVar.accumulator = weaponVar.nextFireTime - tick()
			end
		
			-- start fire loop
			weaponVar.fireLoop = RunService.RenderStepped:Connect(function(dt)
				weaponVar.accumulator += dt
				while weaponVar.accumulator >= weaponOptions.fireRate and hotVariables.mouseDown do
					weaponVar.nextFireTime = tick() + weaponOptions.fireRate
					weaponVar.accumulator -= weaponOptions.fireRate
					task.spawn(function()
						util_fireWithChecks(t, secondaryMouse)
					end)
					if weaponVar.accumulator >= fireRate then task.wait(fireRate) end
				end
			end)

			-- initial fire if necessary
			if startWithInit then
				util_fireWithChecks(t, secondaryMouse)
			end

		end
	end

end

--[[@title 			- conn_disableRecoilConnections
	
	@summary
					- Disables the MouseDown FireLoop for automatic weapons.
	@return			- {void}
]]


function conn_disableRecoilConnections(isAutomatic: boolean)
	if weaponVar.fireLoop then
		weaponVar.fireLoop:Disconnect()
		weaponVar.fireLoop = false
	end
end

--[[@title 			- core_equip
	
	@summary
					- Core weapon equip function
	@return			- {void}
]]

--[[ == INITIATE KEYBIND ACTIONS == ]]

local m_inputs = require(player.PlayerScripts.m_inputs)
local types = m_inputs.Types

function binds_connectHotBinds()
end

function binds_disconnectHotBinds()
end

function core_equip()
	if tool:GetAttribute("IsForceEquip") then
		tool:SetAttribute("IsForceEquip", false)
	else
		if player:GetAttribute("Typing") then return end
		if player.PlayerGui.MainMenu.Enabled then return end
	end

	-- enable weapon icon
	util_setIconEquipped(true)

	-- HUD & Knife Sound
	if weaponOptions.inventorySlot == "ternary" then -- knife
		print('equip knife')
		animationEventFunctions.PlaySound("Equip") -- equip sound
		util_setInfoFrameKnife()
	else
		print('equip weapon')
		util_setInfoFrameWeapon()
	end

	-- var
    forcestop = false
    weaponVar.equipping = true
	States.SetStateVariable("PlayerActions", "weaponEquipping", true)
	States.SetStateVariable("PlayerActions", "weaponEquipped", weaponName)

	-- process equip animation and sounds next frame ( to let unequip run )
	task.spawn(util_processEquipAnimation)
	task.spawn(util_resetSprayOriginPoint)

    -- move model and set motors
    clientModel.Parent = vm.Equipped
    local gripParent = vm:FindFirstChild("RightArm") or vm.RightHand
    gripParent.RightGrip.Part1 = clientModel.GunComponents.WeaponHandle
    
    -- run server equip timer
    task.spawn(function()
        local success = weaponRemoteFunction:InvokeServer("EquipTimer")
        if success and weaponVar.equipping then
            weaponVar.equipped = true
            weaponVar.equipping = false
			States.SetStateVariable("PlayerActions", "weaponEquipping", false)
        end
	end)

	-- set movement speed
	util_handleHoldMovementPenalize(true)
end

--[[@title 			- core_unequip
	@return			- {void}
]]

function core_unequip()
	if not player.Character or hum.Health <= 0 then return end

	-- Resolve: weapon firing after shooting while unequip
	conn_mouseUp(true)

	util_setIconEquipped(false)
	--controllerModule:Unequip(weaponOptions.inventorySlot)

	if weaponVar.equipping then
		weaponRemoteFunction:InvokeServer("EquipTimerCancel")
	end

    clientModel.Parent = reptemp
	weaponVar.equipping = false
	weaponVar.equipped = false
    weaponVar.firing = false
    weaponVar.reloading = false
	weaponVar.inspecting = false
	States.SetStateVariable("PlayerActions", "weaponEquipped", false)
	States.SetStateVariable("PlayerActions", "weaponEquipping", false)
	States.SetStateVariable("PlayerActions", "reloading", false)
	States.SetStateVariable("PlayerActions", "shooting", false)

	task.spawn(function()
		util_resetSprayOriginPoint()
		util_stopAllAnimations()
		weaponCameraObject:StopCurrentRecoilThread()
	end)
	
	util_handleHoldMovementPenalize(false)

end

--[[@title 			- core_inspect
	@return			- {void}
]]

function core_inspect(fadeIn)
	if not weaponVar.animations then return end
	if not weaponVar.animations.client.Inspect then return end
	if not weaponVar.equipped or weaponVar.equipping then return end

	-- force start the hold animation if we are still pulling the weapon out
	if not weaponVar.animations.client.Hold.IsPlaying then
		weaponVar.animations.client.Hold:Play()
	end

	-- time skip or play
	if weaponVar.animations.client.Inspect.IsPlaying then
		local skinModel = clientModel:GetAttribute("SkinModel")
		if skinModel then
			if string.match(skinModel, "default") then skinModel = "default" end
			print(skinModel)
			weaponVar.animations.client.Inspect.TimePosition = weaponOptions.inspectAnimationTimeSkip[string.lower(skinModel)]
		else
			weaponVar.animations.client.Inspect.TimePosition = (weaponOptions.inspectAnimationTimeSkip and (weaponOptions.inspectAnimationTimeSkip.default or weaponOptions.inspectAnimationTimeSkip) or 0)
		end
		
		
	else
		util_playAnimation("client", "Inspect", fadeIn, true, fadeIn)
	end
end

function core_stopInspecting(fadeOut)
	if not weaponVar.animations.client.Inspect then
		return
	end
	weaponVar.animations.client.Inspect:Stop(fadeOut)
end

--[[
	Import Core Functions based on class
]]

-- inherit some functions
task.spawn(function()
	if weaponOptions.inventorySlot == "ternary" then
		init_knife()
	end
end)

local corefunc = script:FindFirstChild("corefunctions") and require(script.corefunctions) or {}
local basecorefunc = require(script:WaitForChild("basecorefunctions"))

for i, v in pairs(corefunc) do
	basecorefunc[i] = v
end

corefunc = basecorefunc
--

-- keys of functions that corefunc will use
coreself = {
	util_RegisterRecoils = util_RegisterRecoils,
	util_playAnimation = util_playAnimation,
	core_stopInspecting = core_stopInspecting,
	remoteEvent = weaponRemoteEvent,
}

core_fire = function()
	if not player.Character or hum.Health <= 0 then return end
	if States.GetStateVariable("PlayerActions", "grenadeThrowing") or States.State("UI"):hasOpenUI() then return end
	local autoReload
	weaponVar, autoReload = corefunc.fire(coreself, player, weaponOptions, weaponVar, weaponCameraObject, animationEventFunctions, tick())
	if autoReload then
		task.spawn(function()
			repeat task.wait() until tick() >= autoReload
			core_reload()
		end)
	end
end

core_reload = function()
	if not player.Character or hum.Health <= 0 then return end
	if States.GetStateVariable("PlayerActions", "grenadeThrowing") or States.State("UI"):hasOpenUI() then return end
	weaponVar = corefunc.reload(coreself, weaponOptions, weaponVar, weaponRemoteFunction)
end

core_secondaryFire = function()
	if not corefunc.secondaryFire then return end
	if not player.Character or hum.Health <= 0 then return end
	if States.GetStateVariable("PlayerActions", "grenadeThrowing") or States.State("UI"):hasOpenUI() then return end
	weaponVar = corefunc.secondaryFire(coreself, player, weaponOptions, weaponVar, weaponCameraObject, animationEventFunctions, tick())
end

--[[local inventoryControllerWeapon = controllerModule.StoredWeaponController:GetInventoryWeaponByName(weaponName, true)
if not inventoryControllerWeapon then error("Could not load " .. player.Name .. "'s WeaponController weapon_" .. weaponName .. " InventoryWeapon") end
inventoryControllerWeapon.CoreFunctions = {
	firedown = conn_mouseDown,
	fireup = conn_mouseUp,
	reload = core_reload,
	startInspect = core_inspect,
	stopInspect = core_stopInspecting,
	secfiredown = function()
		return conn_mouseDown(false, true)
	end
}]]

--[[{                                 }]


    --      START SCRIPT        --


--[{                                 }]]

-- run all inits
init_keybinds()
init_HUD()
init_animations()
init_animationEvents()
init_variables()
init_weaponControllerWeapon()

-- connect connections
connections.equip = tool.Equipped:Connect(core_equip)
connections.unequip = tool.Unequipped:Connect(core_unequip)

-- make server model invisible
local debugServerModel = false
if debugServerModel then
	util_setServerTransparency(0)
else
	util_setServerTransparency(1)
end