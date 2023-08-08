local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Weapon")
local WeaponGetEvent = WeaponRemotes:WaitForChild("Get")
local WeaponAddRemoveEvent = WeaponRemotes:WaitForChild("AddRemove")
local WeaponObjects = ReplicatedStorage:WaitForChild("Objects"):WaitForChild("Weapon")
local WeaponScripts = script.Scripts
local WeaponOptions = script.Options

local Weapon = {}

function Weapon.Add(player, weaponName, forceEquip)
	if not player.Character then return end
	if not player.Character:FindFirstChild("WeaponController") then -- no controller failsafe
		Weapon.AddWeaponController(player.Character)
	end

	local weaponOptions = WeaponOptions:FindFirstChild(weaponName)
	if not weaponOptions or (weaponOptions and not weaponOptions:IsA("ModuleScript") or weaponOptions:GetAttribute("NotWeapon")) then
		error("Could not verify WeaponOptions for " .. weaponName)
	end
	weaponOptions = require(weaponOptions)

	local weaponObjectsFolder

	-- check to see if given weapon name string is a "Knife"
	-- if so, we want to grab the knife skin from DataStore,
	-- and change the location variables since Knives are
	-- named differently than weapons.

	if weaponName == "Knife" then
		-- local skin = playerOptions.inventory.knife.equipped
		weaponObjectsFolder = WeaponObjects:FindFirstChild("Knife_Karambit")
	else
		weaponObjectsFolder = WeaponObjects:FindFirstChild(weaponName)
	end

	if not weaponObjectsFolder then
		error("Could not verify WeaponObjects for " .. weaponName)
	end
	
	local currentInventory = WeaponGetEvent:InvokeClient(player)
	local currWeaponInSlot = currentInventory[weaponOptions.inventorySlot]
	if currWeaponInSlot then
		Weapon.Remove(player, currWeaponInSlot)
	end
	
	local tool = Instance.new("Tool")
	tool.RequiresHandle = false
	tool.Name = "Tool_" .. weaponName

	local model = weaponObjectsFolder.Models.Default
	local serverModel
	local clientModel
	local serverScript
	local clientScript

	if model:FindFirstChild("Server") then
		serverModel = model.Server:Clone()
		clientModel = model:Clone()
		clientModel:WaitForChild("Server"):Destroy()
	else
		serverModel = model:Clone()
		clientModel = serverModel:Clone()
	end

	serverModel.Name = "ServerModel"
	serverModel.Parent = tool
	clientModel.Name = "ClientModel"
	clientModel.Parent = ReplicatedStorage:WaitForChild("Temp")

	-- knife
	if weaponOptions.inventorySlot == "ternary" then
		clientScript = WeaponScripts.KnifeClient:Clone()
		serverScript = WeaponScripts.KnifeServer:Clone()
	else
	-- weapon
		clientScript = WeaponScripts.WeaponClient:Clone()
		serverScript = WeaponScripts.WeaponServer:Clone()
	end

	clientScript.Parent = tool
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

	-- Force Equip
	--[[task.wait()
	if forceEquip then
		player.Character:WaitForChild("Humanoid"):EquipTool(tool)
	end]]
end

function Weapon.Remove(player, weaponName)
	if not player.Character then return end
	local tool = player.Character:FindFirstChild("Tool_" .. weaponName)
	if not tool then tool = player.Backpack:FindFirstChild("Tool_" .. weaponName) else player.Character.Humanoid:UnequipTools() end
	if not tool then
		warn("Could not find player's weapon " .. weaponName .. " to remove.")
		return
	end
	
	WeaponAddRemoveEvent:FireClient(player, "Remove", weaponName, tool)
	tool:Destroy()
end

function Weapon.AddWeaponController(char)
	local controller = script.WeaponController:Clone()
	controller.Parent = char
end

function Weapon.GetWeaponController(player)
	return player.Character:FindFirstChild("WeaponController")
end

function Weapon.ClearPlayerInventory(player)
	local currentInventory = WeaponGetEvent:InvokeClient(player)
	if not currentInventory then return end
	for i, v in pairs(currentInventory) do
		if v then
			Weapon.Remove(player, v)
		end
	end
end

function Weapon.ClearAllPlayerInventories()
	for _, player in pairs(Players:GetPlayers()) do
		if not player.Character then continue end
		task.spawn(function()
			Weapon.ClearPlayerInventory(player)
		end)
	end
end

return Weapon