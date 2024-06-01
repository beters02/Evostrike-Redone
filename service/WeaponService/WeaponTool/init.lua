if game:GetService("RunService"):IsClient() then return end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
--local InventoryInterface = require(Framework.shfc_inventoryPlayerDataInterface.Location)
local InventoryInterface2 = require(Framework.Module.InventoryInterface)

local ServiceAssets = script.Parent:WaitForChild("ServiceAssets")
local WeaponClient = script:WaitForChild("WeaponClient")
local WeaponServer = script:WaitForChild("WeaponServer")

local WeaponTool = {}

function WeaponTool.new(player: Player, weaponModule: ModuleScript)
	local serverModel
	local clientModel
	local tool
	local model
	local weaponName = require(weaponModule).Configuration.name

	tool = Instance.new("Tool")
	tool.RequiresHandle = false
	tool.Name = "Tool_" .. weaponName

	-- get weapon skin
	print(weaponName)
	local invSkin, skinData = InventoryInterface2.GetEquippedSkin(player, string.lower(weaponName))
	print(invSkin)
	model = InventoryInterface2.GetSkinModelFromSkinObject(invSkin)

	-- set collision groups
	for _, v in pairs(model:GetDescendants()) do
		if not v:IsA("MeshPart") and not v:IsA("BasePart") then continue end
		v.CollisionGroup = "Weapons"
		v.Massless = true
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

	if model:FindFirstChild("Inventory") then
		model.Inventory:Destroy()
	end

	-- Disable shadows on client model
	for _, v in pairs(clientModel:GetDescendants()) do
		if v:IsA("Part") or v:IsA("MeshPart") then
			v.CastShadow = false
		end
	end

	serverModel.Name = "ServerModel"
	serverModel.Parent = tool
	clientModel.Name = "ClientModel"
	clientModel.Parent = ReplicatedStorage:WaitForChild("temp")

	clientModel:SetAttribute("Skin", tostring(invSkin.skin))
	if invSkin.model then
		clientModel:SetAttribute("SkinModel", tostring(invSkin.model))
	end

	-- add necessary particles
	if string.lower(weaponName) ~= "knife" then
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
	clientScript:SetAttribute("weaponName", weaponName)
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
	local weaponServerReloadedEvent = Instance.new("RemoteEvent")
	weaponServerReloadedEvent.Name = "WeaponServerReloadedEvent"
	weaponServerReloadedEvent.Parent = tool
	
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
	WeaponObjectsFolderObject.Value = weaponModule.Assets
	WeaponObjectsFolderObject.Parent = tool
	local WeaponModuleObject = Instance.new("ObjectValue")
	WeaponModuleObject.Name = "WeaponModuleObject"
	WeaponModuleObject.Value = weaponModule
	WeaponModuleObject.Parent = tool

	tool.Parent = game:GetService("ServerStorage")
	return tool, clientModel, serverModel
end

return WeaponTool