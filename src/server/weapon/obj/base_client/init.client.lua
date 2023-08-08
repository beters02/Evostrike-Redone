local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")

--local PlayerOptions = require(ReplicatedScripts:WaitForChild("Modules"):WaitForChild("PlayerOptions"))

local SharedMovementFunctions = Framework.fc_sharedMovementFunctions.Module
local SharedWeaponFunctions = Framework.fc_sharedWeaponFunctions.Module

local CustomString = SharedWeaponFunctions
local Strings = Framework.shfc_strings.Module
local Math = Framework.shfc_math.Module
local VMSprings = Framework.shc_vmsprings.Module

local WeaponRemotes = ReplicatedStorage:WaitForChild("weapon"):WaitForChild("remote")
local Temp = ReplicatedStorage:WaitForChild("temp")

local tool = script.Parent
local clientModel = tool:WaitForChild("ClientModelObject").Value
local serverModel = tool.ServerModel
local weaponName = string.gsub(tool.Name, "Tool_", "")
local weaponRemoteFunction = tool:WaitForChild("WeaponRemoteFunction")
local weaponRemoteEvent = tool:WaitForChild("WeaponRemoteEvent")
local weaponGetRemote = WeaponRemotes:WaitForChild("get")
--local weaponReplicateRemote = WeaponRemotes:WaitForChild("replicate")
local weaponObjectsFolder = tool:WaitForChild("WeaponObjectsFolderObject").Value

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local vm = camera:WaitForChild("viewModel")
local mouse = player:GetMouse()

local weaponOptions = weaponGetRemote:InvokeServer("Options", weaponName)
local weaponVar = {
	equipped = false,
	equipping = false,
	firing = false,
	reloading = false,
	
	currentBullet = 1,
	nextFireTime = 0,
	lastFireTime = 0,
	
	ammo = {
		magazine = weaponOptions.ammo.magazine,
		total = weaponOptions.ammo.total
	},
	
	fireDebounce = false,
	fireLoop = false,
	fireScheduled = false,
	
	lastYAcc = 0
}

--[[local AccuracyCalculator = require(game:GetService("ReplicatedStorage"):WaitForChild("Scripts"):WaitForChild("Modules"):WaitForChild("AccuracyCalculator")).init(player, weaponOptions)
local CalculateAccuracy = AccuracyCalculator.Calculate]]
local CameraObject = Framework.shc_cameraObject.New(weaponName)

--[[ INIT ]]

local weaponBar
local weaponFrame
local weaponIconEquipped
local weaponIconUnequipped

local hudCharClass
local hudChar
local hcModel

local viewmodelScript
local vmAnimController

local VMEquipSpring
local connectVMSpringEvent
local weaponSounds

local animationEventFunctions = {}
local currentPlayingWeaponSounds = {}

--[[@title 			- initHUDGui
	
	@summary
					- Initializes the weapon frames (weapon icons) on the Main Menu HUD GUI

	@return			- {void}
]]

local function initHUDGui()
	weaponBar = player.PlayerGui:WaitForChild("HUD").WeaponBar
	weaponFrame = weaponBar:WaitForChild(Strings.firstToUpper(weaponOptions.inventorySlot))
	weaponIconEquipped = weaponFrame:WaitForChild("EquippedIconLabel")
	weaponIconUnequipped = weaponFrame:WaitForChild("UnequippedIconLabel")
	weaponIconEquipped.Image = weaponObjectsFolder.Images.EquippedIcon.Image
	weaponIconUnequipped.Image = weaponObjectsFolder.Images.UnequippedIcon.Image
	weaponFrame.Visible = true
end

--[[@title 			- initHUDChar
	
	@summary
					- HUDCharacter's weapon model.

	@return			- {void}
]]

local hudCharEnabled = false

--[[local function initHUDChar()
	local hudCharModule = require(Libraries.HUDCharacter)
	hudCharClass = hudCharModule.GetHUDCharacter()
	if typeof(hudCharClass) == "RBXScriptSignal" then hudCharClass = hudCharClass:Wait() end
	hudChar = hudCharClass.model
	if not hudChar then warn("Couldn't load Weapon HUDCharacter!") else
		-- init hudChar model
		hcModel = serverModel:Clone()
		hcModel.Parent = player.Backpack
	end
end]]

--[[@title 			- initAnimations
	
	@summary
					- Init all Weapon Animations for all player models including:
					- Server (humanoid), Client (viewModel), HUDChar (hcModel)

	@return			- {void}
]]

local function initAnimations()
	local animationsFolder = weaponObjectsFolder.Animations

	-- init anims table
	weaponVar.animations = {client = {}, server = {}, clienthud = {}}

	-- grab viewmodel script for animation events
	viewmodelScript = char:WaitForChild("ViewmodelScript")

	-- init client anim controller
	vmAnimController = vm.AnimationController
	connectVMSpringEvent = viewmodelScript:WaitForChild("ConnectVMSpring")

	for _, client in pairs(animationsFolder:GetChildren()) do

		-- init server animations
		if client.Name == "Server" then
			for _, server in pairs(client:GetChildren()) do
				weaponVar.animations.server[server.Name] = hum.Animator:LoadAnimation(server)
				if hudChar then
					weaponVar.animations.clienthud[server.Name] = hudCharClass.LoadAnimation(server)
				end
			end
			continue
		elseif client.ClassName ~= "Animation" then continue end
	
		-- init client animations
		weaponVar.animations.client[client.Name] = vmAnimController:LoadAnimation(client)
	end
end

--[[@title 			- initAnimationEvents
	
	@summary
					- Init all Weapon Animation Event Functions for player models including:
					- Server (humanoid), Client (viewModel), HUDChar (hcModel)

	@return			- {void}
]]

local function initAnimationEvents()

	animationEventFunctions = {}

	-- [[ ANIMATION EVENT FUNCTIONS ]]

	-- viewmodel spring
	animationEventFunctions.VMSpring = function(param)
		print(param)
		if param == "Equip" then
			VMEquipSpring.Force = 80
			VMEquipSpring.Speed = 6
			VMEquipSpring.Damping = 2.5
			VMEquipSpring:shove(Vector3.new(-0.4, -0.4, 0))
		elseif param == "Equip3" then
			VMEquipSpring.Force = 40
			VMEquipSpring.Speed = 6
			VMEquipSpring.Damping = 4
			VMEquipSpring:shove(Vector3.new(math.random(5, 7) / 100, -(math.random(5,7)/100)))
		elseif param == "EquipFinal" then
			VMEquipSpring.Force = 40
			VMEquipSpring.Speed = 6
			VMEquipSpring.Damping = 2.5
			VMEquipSpring:shove(Vector3.new(math.random(20, 30) / 100, -(math.random(10,20)/100)))
		end
	end

	-- viewmodel spring update

	VMEquipSpring = VMSprings:new(9, 80, 4, 7)

	-- this is the update function that will be connected to the viewmodel script
	local _updateFunction = function(dt, hrp)
		local ues = VMEquipSpring:update(dt)
		return hrp.CFrame * CFrame.Angles(ues.X, ues.Y, 0)
	end

	-- this is the string that will be used to index the spring in the viewmodel script
	local springIndexStr = weaponName .. "_Equip"

	-- connect equip spring update event function to viewmodel script
	connectVMSpringEvent:Fire(true, VMEquipSpring, springIndexStr, _updateFunction)
	
	-- weapon sounds
	weaponSounds = weaponObjectsFolder:WaitForChild("Sounds")

	-- play weapon sound
	animationEventFunctions.PlaySound = function(soundName, dontDestroyOnRecreate)
		local _weaponName = weaponName
		if dontDestroyOnRecreate then _weaponName = false end

		local sound = weaponSounds:FindFirstChild(soundName)
		return SharedWeaponFunctions.PlaySound(player.Character, _weaponName, sound)
	end

	-- play replicated weapon sound (replicate to server)
	animationEventFunctions.PlayReplicatedSound = function(soundName, dontDestroyOnRecreate)
		local sound = weaponSounds:FindFirstChild(soundName)
		local _weaponName = weaponName
		if dontDestroyOnRecreate then _weaponName = false end

		-- fire event (WeaponModuleScript.server.lua) to replicate to (WeaponModuleClientScript.client.lua)
		--weaponReplicateRemote:FireServer("PlaySound", char, _weaponName, sound)

		-- play sound on local client
		SharedWeaponFunctions.PlaySound(player.Character, _weaponName, sound)
	end

	
end

--
----
-- [[ RUN ALL INIT FUNCTIONS HERE ]]
----
--

initHUDGui()
--initHUDChar()
initAnimations()
initAnimationEvents()

--[[
	Camera Functions
]]

function CameraEquip()
end

function CameraUnequip()
	CameraObject:StopRecoil()
end

--[[
	HUD Char Functions
]]

local function hcEquip() -- model
	if not hudChar then return end
	hcModel.Parent = hudChar
	local weaponHandle = hcModel.GunComponents.WeaponHandle
	local grip = Instance.new("Motor6D")
	grip.Name = "RightGrip"
	grip.Parent = hudChar.RightHand
	grip.Part0 = hudChar.RightHand
	grip.Part1 = weaponHandle
end

local function hcUnequip() -- model
	if not hudChar or not char or hum.Health <= 0 then return end
	hcModel.Parent = player.Backpack
end

--[[
	Weapon Functions
]]

local connections = {}
local hotConnections = {}
local forcestop = false

--[[
	ANIMATION, VM, ICON FUNCTIONS
]]

function PlayWeaponAnimaton(location, name)
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

function StopAllAnimations()
	forcestop = true
    for _, a in pairs(weaponVar.animations) do
        for _, v in pairs(a) do
            if v.IsPlaying then v:Stop() end
        end
    end
	task.wait(0.06)
	forcestop = false
end

function SetVMTransparency(t)
    task.spawn(function()
        for i, v in pairs(vm:GetDescendants()) do
            if v:IsA("MeshPart") or v:IsA("BasePart") then
                if v.Name == "HumanoidRootPart" or v.Name == "WeaponHandle" or v.Name == "WeaponTip" then continue end
                v.Transparency = t
            end
        end
    end)
end

local function SetIconEquipped(equipped)
	if equipped then
		weaponIconUnequipped.Visible = false
		weaponIconEquipped.Visible = true
	else
		weaponIconUnequipped.Visible = true
		weaponIconEquipped.Visible = false
	end
end

function EquipAnimation()

	SetIconEquipped(true)

    task.spawn(function() -- client
        SetVMTransparency(1)
        task.delay(0.07, function()
            SetVMTransparency(0)
        end)
		local clientPullout = PlayWeaponAnimaton("client", "Pullout")
		clientPullout.Stopped:Wait()
        --weaponVar.animations.client.Pullout:Play()
        --weaponVar.animations.client.Pullout.Stopped:Wait()
		
		if forcestop then return end
        if not weaponVar.equipped and not weaponVar.equipping then return end
        weaponVar.animations.client.Hold:Play()
    end)

    task.spawn(function() -- server
        weaponVar.animations.server.Pullout:Play()
        weaponVar.animations.server.Pullout.Stopped:Wait()
        if not weaponVar.equipped and not weaponVar.equipping then return end
        weaponVar.animations.server.Hold:Play()
    end)

	task.spawn(function() -- hud char
		if not hudChar then return end
		weaponVar.animations.clienthud.Pullout:Play()
		weaponVar.animations.clienthud.Pullout.Stopped:Wait()
		if forcestop then return end
        if not weaponVar.equipped and not weaponVar.equipping then return end
        weaponVar.animations.clienthud.Hold:Play()
	end)
    
end

--[[
	WEAPON TOOL FUNCTIONALITY
]]

function Equip()
	if weaponVar.equipped or weaponVar.equipping then return end
	forcestop = false
	task.spawn(EnableHotConn)
	task.spawn(CameraEquip)
	weaponVar.equipping = true
	
	clientModel.Parent = vm.Equipped
	local gripParent = vm:FindFirstChild("RightArm") or vm.RightHand
	gripParent.RightGrip.Part1 = clientModel.GunComponents.WeaponHandle
	
	task.spawn(function()
		weaponRemoteFunction:InvokeServer("Timer", "Equip")
		if weaponVar.equipping then
			weaponVar.equipped = true
			weaponVar.equipping = false
		end
	end)

	task.spawn(function()
		hcEquip()
		EquipAnimation()
	end)
end

function Unequip()
	clientModel.Parent = Temp
	weaponVar.equipping = false
	weaponVar.equipped = false
    weaponVar.firing = false
    weaponVar.reloading = false
	task.spawn(DisableHotConn)
	task.spawn(CameraUnequip)
	task.spawn(hcUnequip)
	task.spawn(StopAllAnimations)
	SetIconEquipped(false)
end

function Fire()

	-- set var
	local t = tick()
	local mosPos = Vector2.new(mouse.X, mouse.Y)
	local fireRegisterTime = workspace:GetServerTimeNow()
	weaponVar.fireLoop = true
	weaponVar.firing = true
	weaponVar.nextFireTime = t + weaponOptions.fireRate
	weaponVar.ammo.magazine -= 1
	weaponVar.currentBullet = (t - weaponVar.lastFireTime >= weaponOptions.recoilReset and 1 or weaponVar.currentBullet + 1)
	weaponVar.lastFireTime = t
	CameraObject.weaponVar.currentBullet = weaponVar.currentBullet

	RegisterFireRayAndCameraRecoil()

	-- play animations
	PlayWeaponAnimaton("client", "Fire")
    --weaponVar.animations.client.Fire:Play()
    weaponVar.animations.server.Fire:Play()
	if hudChar then weaponVar.animations.clienthud.Fire:Play() end

	-- play sounds
	task.spawn(function()
		animationEventFunctions.PlayReplicatedSound("Fire", true)
		--animationEventFunctions.PlaySound("Fire")
	end)
	
	task.spawn(function() -- client fire rate
		local nextFire = t + weaponOptions.fireRate
		repeat task.wait() until tick() >= nextFire
		weaponVar.firing = false
	end)
end

function Reload()
	if weaponVar.ammo.total <= 0 then return end
	if weaponVar.firing or weaponVar.reloading or not weaponVar.equipped then return end
	
	task.spawn(function()
		weaponVar.animations.client.Reload:Play()
		--weaponVar.animations.server.Reload:Play() TODO: make server reload animations
	end)

	weaponVar.reloading = true
	local mag, total = weaponRemoteFunction:InvokeServer("Reload")
	weaponVar.ammo.magazine = mag
	weaponVar.ammo.total = total
	weaponVar.reloading = false
end

--[[
	ACCURACY, RECOIL, BULLET STUFF
]]

local function GetNewTargetRay(mousePos, acc)
	return camera:ScreenPointToRay(mousePos.X + -acc.X, mousePos.Y + -acc.Y)
end

local function GetFireCastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, camera, workspace.Temp}
	params.CollisionGroup = "Bullets"
	return params
end

local function createRayInformation(unitRay, result)
	if not result then return end
	return {origin = unitRay.Origin, direction = unitRay.Direction, instance = result.Instance, position = result.Position, normal = result.Normal, distance = result.Distance, material = result.Material}
end

function RegisterFireRayAndCameraRecoil()

	print('start fire ray')

	task.spawn(function()
		local m = player:GetMouse()
		local mray = GetNewTargetRay(Vector2.new(m.X, m.Y), Vector2.zero)

		print("get client accuracy")

		local currVecOption = CameraObject:GetSprayPatternKey()			
		local currVecRecoil = CameraObject:GetRecoilVector3(currVecOption)	-- convert VectorRecoil or SpreadRecoil key into a Vector3
		local acc = Vector2.new(1,1)
		--acc, weaponVar = CalculateAccuracy(weaponVar.currentBullet, currVecRecoil, weaponVar, false, false, Framework.fc_sharedMovementFunctions) -- update weaponVar on accuracy? i need to change that
		--local caccvec = AccuracyCalculator.GetMovementInaccuracyVector2((weaponOptions.accuracy.firstBullet and weaponVar.currentBullet == 1) or false)
        local caccvec = Vector2.new(1,1)

		print("get client accuracy")

		-- register client ray using client accuracy
		local direction = mray.Direction
		direction = Vector3.new(direction.X + acc.X/500, direction.Y + acc.Y/500, direction.Z).Unit

		-- if weapon is a spread weapon, add inaccuracy on the X vec
		--[[if weaponOptions.spread then
			direction = Vector3.new(direction.X + acc.X/500, direction.Y + acc.Y/500, direction.Z).Unit
		else
		
		-- else, only add it on the Y vec (spray patterns)
			direction = Vector3.new(direction.X, direction.Y + acc.Y/500, direction.Z).Unit
		end]]

		--if not mouse then mouse = player:GetMouse() end
		--local mp = Vector2.new(mouse.X, mouse.Y)
		--local unitRay = GetNewTargetRay(mp, acc)
		local unitRay = mray

		-- get server register time
		--local fireRegisterTime = workspace:GetServerTimeNow()

		-- get result
		local params = GetFireCastParams()
		local result = workspace:Raycast(unitRay.Origin, direction * 100, params) print(result)
		
		print("get client accuracy")

		if result then
			print("get client result")
			-- register client shot for bullet/blood/sound effects
			SharedWeaponFunctions.RegisterShot(player, weaponOptions, result, unitRay.Origin)

			-- pass ray information to server for verification and damage
			local rayInformation = createRayInformation(unitRay, result)

			task.spawn(function()
				local hitRegistered, newAccVec = weaponRemoteFunction:InvokeServer("Fire", weaponVar.currentBullet, caccvec, rayInformation, workspace:GetServerTimeNow())
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
	CameraObject:FireRecoil(weaponVar.currentBullet)
	
end

--[[
	StopRecoil

	turn off fireLoop when mouse is let go
]]
local fireKeyOptionName = "Key_PrimaryFire"
function StopRecoil(auto)
	repeat task.wait() until not weaponVar.firing
	--[[if (auto and UserInputService:IsMouseButtonPressed(Enum.UserInputType[PlayerOptions[fireKeyOptionName]) or weaponVar.ammo.magazine <= 0) then
		return
	end]]

    if (auto and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or weaponVar.ammo.magazine <= 0) then
		return
	end
	weaponVar.fireLoop = false
end

--[[
	Connection Functions
]]

-- hot connections are ones to be disabled/enabled upon unequip/equip
function HotFire()
	if not weaponVar.equipped or weaponVar.fireDebounce or weaponVar.reloading or weaponVar.ammo.magazine <= 0 then return end
	weaponVar.fireDebounce = true
	Fire()

	if weaponOptions.automatic then
		weaponVar.fireDebounce = false
	else
		StopRecoil(false)
	end
end

function MouseDown(t)
	if weaponVar.fireScheduled then
		if t >= weaponVar.fireScheduled then -- if schedule time is reached
			weaponVar.fireScheduled = false
			HotFire()
		end
		return -- if there is already a fire scheduled we dont need to do anything
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
	HotFire()
end

local function MouseUp(t)
	if weaponVar.fireLoop then
		StopRecoil(true)
	end

	if not weaponOptions.automatic then
		if weaponVar.firing then repeat task.wait() until not weaponVar.firing end
		weaponVar.fireDebounce = false
	end
end


function EnableHotConn()
	--[[hotConnections.fireCheck = game:GetService("RunService").RenderStepped:Connect(function()
		local t = tick()
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType[PlayerOptions[fireKeyOptionName]) then
			return MouseDown(t)
		else
			return MouseUp(t)
		end
	end)]]

    hotConnections.fireCheck = game:GetService("RunService").RenderStepped:Connect(function()
		local t = tick()
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			return MouseDown(t)
		else
			return MouseUp(t)
		end
	end)
	
	hotConnections.reloadCheck = UserInputService.InputBegan:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.R then
			Reload()
		end
	end)
end

function DisableHotConn()
	for i, v in pairs(hotConnections) do
		v:Disconnect()
	end
end

--[[ 
	Connections
]]

--[[ TOOL EQUIP INPUT CONNECTIONS ]]
local equipKeyOptionName = "Key_" .. Strings.firstToUpper(weaponOptions.inventorySlot) .. "Weapon"
--[[connections.equipInputBegin = UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode[PlayerOptions[equipKeyOptionName] then
		if not weaponVar.equipping and not weaponVar.equipped then
			hum:EquipTool(tool)
		end
	end
end)]]

local s = weaponOptions.inventorySlot
local tempequip = s == "primary" and "One" or s == "secondary" and "Two" or "Three"

connections.equipInputBegin = UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode[tempequip] then
		if not weaponVar.equipping and not weaponVar.equipped then
			hum:EquipTool(tool)
		end
	end
end)

--[[ TOOL EQUIP ROBLOX CONNECTIONS ]]
connections.equip = tool.Equipped:Connect(Equip)
connections.unequip = tool.Unequipped:Connect(Unequip)

--[[
	Init
]]

-- make server model invisible
local makeServerModelInvis = true
if makeServerModelInvis then
	for i, v in pairs(serverModel:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("MeshPart") then
			v.Transparency = 1
		end
	end
end