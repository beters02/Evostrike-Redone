local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ReplicatedScripts = ReplicatedStorage:WaitForChild("Scripts")
local PlayerOptions = require(ReplicatedScripts:WaitForChild("Modules"):WaitForChild("PlayerOptions"))
local Libraries = ReplicatedStorage:WaitForChild("Scripts"):WaitForChild("Libraries")
local CustomString = require(Libraries:WaitForChild("WeaponFireCustomString"))
local Strings = require(Libraries:WaitForChild("Strings"))
local Math = require(Libraries:WaitForChild("Math"))
local FESpring = require(Libraries:WaitForChild("FESpring"))
local WeaponRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Weapon")
local Temp = ReplicatedStorage:WaitForChild("Temp")
local WeaponFunctions = require(ReplicatedStorage.Scripts.Libraries.WeaponFunctions)

local tool = script.Parent
local clientModel = tool:WaitForChild("ClientModelObject").Value
local serverModel = tool.ServerModel
local weaponName = string.gsub(tool.Name, "Tool_", "")
local weaponRemoteFunction = tool:WaitForChild("WeaponRemoteFunction")
local weaponRemoteEvent = tool:WaitForChild("WeaponRemoteEvent")
local weaponGetRemote = WeaponRemotes:WaitForChild("Get")
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

local AccuracyCalculator = require(game:GetService("ReplicatedStorage"):WaitForChild("Scripts"):WaitForChild("Modules"):WaitForChild("AccuracyCalculator")).init(player, weaponOptions)
local CalculateAccuracy = AccuracyCalculator.Calculate

local CameraObject = require(script:WaitForChild("CameraObject")).new(weaponName)

--[[
	Init HUD GUI
]]

local weaponBar = player.PlayerGui:WaitForChild("HUD").WeaponBar
local weaponFrame = weaponBar:WaitForChild(Strings.firstToUpper(weaponOptions.inventorySlot))
local weaponIconEquipped = weaponFrame:WaitForChild("EquippedIconLabel")
local weaponIconUnequipped = weaponFrame:WaitForChild("UnequippedIconLabel")
weaponIconEquipped.Image = weaponObjectsFolder.Images.EquippedIcon.Image
weaponIconUnequipped.Image = weaponObjectsFolder.Images.UnequippedIcon.Image


weaponFrame.Visible = true

--[[
    Init Animations
]]

weaponVar.animations = {client = {}, server = {}}
local vmAnimController = vm.AnimationController
local animationsFolder = weaponObjectsFolder.Animations
for _, client in pairs(animationsFolder:GetChildren()) do

    -- init server animations
    if client.Name == "Server" then
        for _, server in pairs(client:GetChildren()) do
            weaponVar.animations.server[server.Name] = hum.Animator:LoadAnimation(server)
        end
        continue
    end

    -- init client animations
    weaponVar.animations.client[client.Name] = vmAnimController:LoadAnimation(client)

end

--[[
	Camera Functions
]]

function CameraEquip()
end

function CameraUnequip()
	CameraObject:StopRecoil()
end

--[[
	Weapon Functions
]]

local connections = {}
local hotConnections = {}

function StopAllAnimations()
    for _, a in pairs(weaponVar.animations) do
        for _, v in pairs(a) do
            if v.IsPlaying then v:Stop() end
        end
    end
end

function SetVMTransparency(t)
    task.spawn(function()
        for i, v in pairs(vm:GetDescendants()) do
            if v:IsA("MeshPart") or v:IsA("BasePart") then
                if v.Name == "HumanoidRootPart" then continue end
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

function Equip()
	if weaponVar.equipped or weaponVar.equipping then return end
	task.spawn(EnableHotConn)
	task.spawn(CameraEquip)
	weaponVar.equipping = true
	
	clientModel.Parent = vm.Equipped
	vm.RightArm.RightGrip.Part1 = clientModel.GunComponents.WeaponHandle
	
	task.spawn(function()
		weaponRemoteFunction:InvokeServer("Timer", "Equip")
		if weaponVar.equipping then
			weaponVar.equipped = true
			weaponVar.equipping = false
		end
	end)

    EquipAnimation()
end

function EquipAnimation()

	SetIconEquipped(true)

    task.spawn(function() -- client
        SetVMTransparency(1)
        task.delay(0.07, function()
            SetVMTransparency(0)
        end)
        weaponVar.animations.client.Pullout:Play()
        weaponVar.animations.client.Pullout.Stopped:Wait()
        if not weaponVar.equipped and not weaponVar.equipping then return end
        weaponVar.animations.client.Hold:Play()
    end)

    task.spawn(function() -- server
        weaponVar.animations.server.Pullout:Play()
        weaponVar.animations.server.Pullout.Stopped:Wait()
        if not weaponVar.equipped and not weaponVar.equipping then return end
        weaponVar.animations.server.Hold:Play()
    end)
    
end

function Unequip()
	task.spawn(DisableHotConn)
	task.spawn(CameraUnequip)
    task.spawn(StopAllAnimations)
	SetIconEquipped(false)
	weaponVar.equipping = false
	weaponVar.equipped = false
    weaponVar.firing = false
    weaponVar.reloading = false
	clientModel.Parent = Temp
end

local function GetNewTargetRay(mousePos, acc)
	return camera:ScreenPointToRay(mousePos.X + -acc.X, mousePos.Y + -acc.Y)
end

function Fire()

	-- set var
	weaponVar.fireLoop = true
	weaponVar.firing = true
	local t = tick()
	weaponVar.nextFireTime = t + weaponOptions.fireRate
	weaponVar.ammo.magazine -= 1
	weaponVar.currentBullet = (t - weaponVar.lastFireTime >= weaponOptions.recoilReset and 1 or weaponVar.currentBullet + 1)
	CameraObject.weaponVar.currentBullet = weaponVar.currentBullet
	weaponVar.lastFireTime = t
	
	local currVecOption, currShakeOption = CameraObject:GetSprayPatternKey()			-- get recoil pattern key
	local currVecRecoil = CameraObject:GetRecoilVector3(currVecOption)				-- convert VectorRecoil or SpreadRecoil key into a Vector3
	--local currShakeRecoil = cameraClass:GetRecoilVector3(currShakeOption)			-- convert ShakeRecoil key into a Vector3
	
	-- init paramaters for client bullet registration
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, camera, workspace.Temp}
	params.CollisionGroup = "Bullets"

	-- play animations
    weaponVar.animations.client.Fire:Play()
    weaponVar.animations.server.Fire:Play()
	
	task.spawn(function() -- client fire rate
		local nextFire = t + weaponOptions.fireRate
		repeat task.wait() until tick() >= nextFire
		weaponVar.firing = false
	end)
	
	local mosPos = Vector2.new(mouse.X, mouse.Y)
	
	task.spawn(function() -- client accuracy & bullet, fire camera spring
		local clientAcc
		clientAcc, weaponVar = CalculateAccuracy(weaponVar.currentBullet, currVecRecoil, weaponVar)
		local unitRay = GetNewTargetRay(mosPos, clientAcc)
		task.spawn(function() -- camera spring is fired after the accuracy is registered, to avoid bullets going in the wrong place.
			CameraObject:FireRecoil(weaponVar.currentBullet)
		end)
		task.spawn(function()
			local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 100, params)
			if not result then return end
			WeaponFunctions.RegisterShot(player, weaponOptions, result, unitRay.Origin)
		end)
	end)
	
	task.spawn(function() -- server accuracy
		local serverAcc = weaponRemoteFunction:InvokeServer("GetAccuracy", currVecRecoil, weaponVar.currentBullet, char.HumanoidRootPart.Velocity.Magnitude)
		--print(tostring(serverAcc) .. " server accuracy")
		local finalRay = GetNewTargetRay(mosPos, serverAcc)
		local serverBulletHole = weaponRemoteFunction:InvokeServer("Fire", finalRay, weaponVar.currentBullet, currVecRecoil)
		if serverBulletHole then serverBulletHole:Destroy() end
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
	StopRecoil

	turn off fireLoop when mouse is let go
]]
local fireKeyOptionName = "Key_PrimaryFire"
function StopRecoil(auto)
	repeat task.wait() until not weaponVar.firing
	if (auto and UserInputService:IsMouseButtonPressed(Enum.UserInputType[PlayerOptions[fireKeyOptionName]]) or weaponVar.ammo.magazine <= 0) then
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
	hotConnections.fireCheck = game:GetService("RunService").RenderStepped:Connect(function()
		local t = tick()
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType[PlayerOptions[fireKeyOptionName]]) then
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

local equipKeyOptionName = "Key_" .. Strings.firstToUpper(weaponOptions.inventorySlot) .. "Weapon"
connections.equipInputBegin = UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode[PlayerOptions[equipKeyOptionName]] then
		if not weaponVar.equipping and not weaponVar.equipped then
			hum:EquipTool(tool)
		end
	end
end)

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