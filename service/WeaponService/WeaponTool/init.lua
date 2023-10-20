if game:GetService("RunService"):IsClient() then return end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local InventoryInterface = require(Framework.shfc_inventoryPlayerDataInterface.Location)

local ServiceAssets = script.Parent:WaitForChild("ServiceAssets")
local WeaponClient = script:WaitForChild("WeaponClient")
local WeaponServer = script:WaitForChild("WeaponServer")

local WeaponTool = {}

function WeaponTool.new(player: Player, weaponModule: ModuleScript)
	local weapon = require(weaponModule).Configuration.name
	local weaponAssets = weaponModule.Assets
	local wepLow = string.lower(weapon)

	local serverModel
	local clientModel
	local tool
	local model
	local skinInfo

	tool = Instance.new("Tool")
	tool.RequiresHandle = false
	tool.Name = "Tool_" .. weapon

	-- get weapon skin
	skinInfo = InventoryInterface:GetEquippedWeaponSkin(player, wepLow)
	local success, err

	if skinInfo.model then

		-- ## TEMPORARY KNIFE SKIN NAME = DEFAULT, SET TO ATTACKDEFAULT
		if skinInfo.model == "default" then
			skinInfo.model = "attackdefault"
		end

		success, err = pcall(function()
			model = weaponAssets[skinInfo.model].Models[skinInfo.skin]
		end)
	else
		success, err = pcall(function()
			model = weaponAssets.Models[skinInfo.skin]
		end)
	end

	if not success then
		warn("YOU NEED TO ADD THE WEAPON TO DEFAULTPLAYERDATA TO NEW WEAPON " .. tostring(err))
		InventoryInterface:SetEquippedWeaponSkin(player, wepLow, wepLow == "knife" and "default_default" or "default")
		model = wepLow == "knife" and weaponAssets.default.Models.default or weaponAssets.Models.default
	end

	-- set collision groups
	for _, v in pairs(model:GetDescendants()) do
		if not v:IsA("MeshPart") and not v:IsA("BasePart") then continue end
		v.CollisionGroup = "Weapons"
	end
	
	-- init server and client model
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
	clientModel.Parent = ReplicatedStorage:WaitForChild("temp")

	clientModel:SetAttribute("Skin", tostring(skinInfo.skin))
	if skinInfo.model then
		clientModel:SetAttribute("SkinModel", tostring(skinInfo.model))
	end

	-- add necessary particles
	if string.lower(weapon) ~= "knife" then
		local a
		for i, v in pairs({clientModel, serverModel}) do
			a = ServiceAssets.Emitters.MuzzleFlash:Clone()
			a.Parent = v.GunComponents.WeaponHandle.FirePoint
			a.Enabled = false
		end
	end

	-- create scripts
	local clientScript, serverScript
	local newFolder = Instance.new("Folder") -- create folder
	newFolder.Name = "Scripts"
	clientScript = WeaponClient:Clone()
	clientScript:SetAttribute("weaponName", weapon)
	serverScript = WeaponServer:Clone()
	clientScript.Parent, serverScript.Parent = newFolder, newFolder
	newFolder.Parent = tool

	-- create remotes and objects
	local weaponRemote = Instance.new("RemoteFunction")
	weaponRemote.Name = "WeaponRemoteFunction"
	weaponRemote.Parent = tool
	local weaponRemoteEvent = Instance.new("RemoteEvent")
	weaponRemoteEvent.Name = "WeaponRemoteEvent"
	weaponRemoteEvent.Parent = tool
	local weaponServerEquippedEvent = Instance.new("RemoteEvent")
	weaponServerEquippedEvent.Name = "WeaponServerEquippedEvent"
	weaponServerEquippedEvent.Parent = tool
	
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
	WeaponObjectsFolderObject.Value = weaponAssets
	WeaponObjectsFolderObject.Parent = tool
	local WeaponModuleObject = Instance.new("ObjectValue")
	WeaponModuleObject.Name = "WeaponModuleObject"
	WeaponModuleObject.Value = weaponModule
	WeaponModuleObject.Parent = tool

	tool.Parent = game:GetService("ServerStorage")
	return tool, clientModel, serverModel
end

return WeaponTool