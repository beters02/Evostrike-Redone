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

local defaultKnifeFolder = ReplicatedStorage.Objects.Weapon.Knife_Default

local weaponOptions = weaponGetRemote:InvokeServer("Options", weaponName)
local weaponVar = {
	equipped = false,
	equipping = false,
	firing = false,
	reloading = false,
	
	fireDebounce = false,
	fireLoop = false,
	fireScheduled = false,
    nextFireTime = 0,
	lastFireTime = 0,
}

local CameraObject = require(script:WaitForChild("CameraObject")).new(weaponName)

--[[
	Init HUD GUI
]]

local weaponBar = player.PlayerGui:WaitForChild("HUD").WeaponBar
local weaponFrame = weaponBar:WaitForChild(Strings.firstToUpper(weaponOptions.inventorySlot))
local weaponIconEquipped = weaponFrame:WaitForChild("EquippedIconLabel")
local weaponIconUnequipped = weaponFrame:WaitForChild("UnequippedIconLabel")

local images = weaponObjectsFolder:FindFirstChild("Images") or defaultKnifeFolder.Images
weaponIconEquipped.Image = images.EquippedIcon.Image
weaponIconUnequipped.Image = images.UnequippedIcon.Image
weaponFrame.Visible = true

--[[
	Init HUDChar

	HUDChar animations are initialized in Init Animations
]]

local hudCharModule = require(Libraries.HUDCharacter)

local hudCharClass = hudCharModule.GetHUDCharacter()
if typeof(hudCharClass) == "RBXScriptSignal" then hudCharClass = hudCharClass:Wait() end
local hudChar = hudCharClass.model
local hcModel
if not hudChar then warn("Couldn't load Weapon HUDCharacter!") else
	-- init hudChar model
	hcModel = serverModel:Clone()
	hcModel.Parent = player.Backpack
end

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
	if not hudChar then return end
	hcModel.Parent = player.Backpack
end

--[[
    Init Animations
]]

weaponVar.animations = {client = {}, server = {}, clienthud = {}}
local vmAnimController = vm.AnimationController
local animationsFolder = weaponObjectsFolder:FindFirstChild("Animations") or defaultKnifeFolder.Animations
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
local forcestop = true

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

function EquipAnimation()

	SetIconEquipped(true)

    task.spawn(function() -- client
        SetVMTransparency(1)
        task.delay(0.07, function()
            SetVMTransparency(0)
        end)
        weaponVar.animations.client.Pullout:Play()
        weaponVar.animations.client.Pullout.Stopped:Wait()
        if forcestop then return end
        if not weaponVar.equipped and not weaponVar.equipping then return end
        weaponVar.animations.client.Hold:Play()
    end)

    task.spawn(function() -- server
        weaponVar.animations.server.Pullout:Play()
        weaponVar.animations.server.Pullout.Stopped:Wait()
        if forcestop then return end
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

function Unequip()
    clientModel.Parent = Temp
    weaponVar.equipping = false
	weaponVar.equipped = false
    weaponVar.firing = false
	task.spawn(DisableHotConn)
	task.spawn(CameraUnequip)
    task.spawn(StopAllAnimations)
	task.spawn(hcUnequip)
	SetIconEquipped(false)
end

function Fire()

    local t = tick()
	local mosPos = Vector2.new(mouse.X, mouse.Y)
	local fireRegisterTime = workspace:GetServerTimeNow()
	weaponVar.fireLoop = true
	weaponVar.firing = true
	weaponVar.nextFireTime = t + weaponOptions.fireRate
	weaponVar.lastFireTime = t

    -- cast ray

    task.spawn(function() -- client fire rate
		local nextFire = tick() + weaponOptions.fireRate
		repeat task.wait() until tick() >= nextFire
		weaponVar.firing = false
	end)

end

function SecondaryFire()
    
end

--[[
	Connection Functions
]]

--[[
	StopRecoil

	turn off fireLoop when mouse is let go
]]
local fireKeyOptionName = "Key_PrimaryFire"
function StopRecoil(auto)
	repeat task.wait() until not weaponVar.firing
	if (auto and UserInputService:IsMouseButtonPressed(Enum.UserInputType[PlayerOptions[fireKeyOptionName]])) then
		return
	end
	weaponVar.fireLoop = false
end

-- hot connections are ones to be disabled/enabled upon unequip/equip
function HotFire()
	if not weaponVar.equipped or weaponVar.fireDebounce then return end
	weaponVar.fireDebounce = true
	Fire()
	weaponVar.fireDebounce = false
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