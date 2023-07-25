local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Weapon")
local WeaponGetEvent = WeaponRemotes:WaitForChild("Get")
local WeaponAddRemoveEvent = WeaponRemotes:WaitForChild("AddRemove")
local WeaponObjects = ReplicatedStorage:WaitForChild("Objects"):WaitForChild("Weapon")
local WeaponScripts = script.Scripts
local WeaponOptions = script.Options

local Weapon = {}

function Weapon.Add(player, weaponName)
	local weaponOptions = WeaponOptions:FindFirstChild(weaponName)
	if not weaponOptions or (weaponOptions and not weaponOptions:IsA("ModuleScript") or weaponOptions:GetAttribute("NotWeapon")) then
		error("Could not verify WeaponOptions for " .. weaponName)
	end
	weaponOptions = require(weaponOptions)
	
	local weaponObjectsFolder = WeaponObjects:FindFirstChild(weaponName)
	if not weaponObjectsFolder then
		error("Could not verify WeaponObjects for " .. weaponName)
	end
	
	local currentInventory = WeaponGetEvent:InvokeClient(player)
	local currWeaponInSlot = currentInventory[weaponOptions.inventorySlot]
	if currWeaponInSlot then
		Weapon.Remove(currWeaponInSlot)
	end
	
	local tool = Instance.new("Tool")
	tool.RequiresHandle = false
	tool.Name = "Tool_" .. weaponName
	local serverModel = weaponObjectsFolder.Models.Default:Clone()
	serverModel.Name = "ServerModel"
	serverModel.Parent = tool
	local clientModel = serverModel:Clone()
	clientModel.Name = "ClientModel"
	clientModel.Parent = ReplicatedStorage:WaitForChild("Temp")
	local clientScript = WeaponScripts.WeaponClient:Clone()
	clientScript.Parent = tool
	local serverScript = WeaponScripts.WeaponServer:Clone()
	serverScript.Parent = tool
	
	local weaponRemote = Instance.new("RemoteFunction")
	weaponRemote.Name = "WeaponRemoteFunction"
	weaponRemote.Parent = tool
	local weaponRemoteEvent = Instance.new("RemoteEvent")
	weaponRemoteEvent.Name = "WeaponRemoteEvent"
	weaponRemoteEvent.Parent = tool
	
	local PlayerObject = Instance.new("ObjectValue")
	PlayerObject.Name = "PlayerObject"
	PlayerObject.Value = player
	PlayerObject.Parent = tool
	local ClientModelObject = Instance.new("ObjectValue")
	ClientModelObject.Name = "ClientModelObject"
	ClientModelObject.Value = clientModel
	ClientModelObject.Parent = tool
	local WeaponObjectsFolderObject = Instance.new("ObjectValue")
	WeaponObjectsFolderObject.Name = "WeaponObjectsFolderObject"
	WeaponObjectsFolderObject.Value = weaponObjectsFolder
	WeaponObjectsFolderObject.Parent = tool
	
	tool.Parent = player.Backpack
	serverScript.Enabled = true
	
	-- Add Weapon Client
	WeaponAddRemoveEvent:FireClient(player, "Add", weaponName, weaponOptions, weaponObjectsFolder)
end

function Weapon.Remove(player, weaponName)
	local tool = player.Character:FindFirstChild("Tool_" .. weaponName)
	if not tool then tool = player.Backpack:FindFirstChild("Tool_" .. weaponName) else player.Character.Humanoid:UnequipTools() end
	if not tool then
		error("Could not find player's weapon " .. weaponName .. " to remove.")
	end
	
	tool:Destroy()
	WeaponAddRemoveEvent:FireClient(player, "Remove", weaponName)
end

function Weapon.AddWeaponController(char)
	local controller = script.WeaponController:Clone()
	controller.Parent = char
end

function Weapon.GetWeaponController(player)
	return player.Character:FindFirstChild("WeaponController")
end

function Weapon.AddWeaponMotor(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	local motor = Instance.new("Motor6D")
	motor.Name = "WeaponMotor"
	motor.Parent = hrp
	motor.Part0 = hrp
end

WeaponRemotes.Replicate.OnServerEvent:Connect(function(player, functionName, ...)
	for i, v in pairs(game:GetService("Players"):GetPlayers()) do
		if v == player then continue end
		WeaponRemotes.Weapon.Replicate:FireClient(v, functionName, ...)
	end
end)

return Weapon