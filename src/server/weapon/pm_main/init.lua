--[[ FrameworkType: Server PlayerModule ]]

-- [[ Get Var ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local WeaponRemotes = ReplicatedStorage:WaitForChild("weapon"):WaitForChild("remote")
local WeaponGetEvent = WeaponRemotes.get
local WeaponAddRemoveEvent = WeaponRemotes.addremove
local WeaponScripts = {ServerScriptService.weapon.obj.base_client, ServerScriptService.weapon.obj.base_server}

-- [[ Module ]]
local Weapon = {}

-- StoredPlayerInventories will be initialized upon PlayerAdded in mss_main
Weapon.StoredPlayerInventories = {}

--[[@title 			    - verifyWeaponSanity
	@summary
					    - Verifies weaponOptions, weaponObjectFolder, and isKnife
	
	@return ifVerified  - weaponOptions: table
                        - weaponObjects: Folder
                        - isKnife: boolean

    @return not ifVerified {false}
]]
local function verifyWeaponSanity(weaponName: string)

    local weaponObjectsFolder
    local weaponOptions
    local isKnife
    
    -- verify weapon options, if found return require table
    weaponOptions = ServerScriptService.weapon.config:WaitForChild(string.lower(weaponName))
	if not weaponOptions or (weaponOptions and not weaponOptions:IsA("ModuleScript") or weaponOptions:GetAttribute("NotWeapon")) then
		warn("Could not verify WeaponOptions for " .. weaponName)
        return false
	end

	-- req
	weaponOptions = require(weaponOptions)

	-- check to see if given weapon name string is a "Knife"
	-- if so, we want to grab the knife skin from DataStore,
	-- and change the location variables since Knives are
	-- named differently than weapons.

	if weaponName == "Knife" then
        isKnife = true
		-- get skin here
		weaponObjectsFolder = ReplicatedStorage.weapon.obj:FindFirstChild(string.lower("knife_karambit"))
	else
        isKnife = false
		weaponObjectsFolder = ReplicatedStorage.weapon.obj:FindFirstChild(string.lower(weaponName))
	end

	if not weaponObjectsFolder then
		warn("Could not verify WeaponObjects for " .. weaponName)
        return false
	end

    return weaponOptions, weaponObjectsFolder, isKnife
end

--[[@title 			    - checkPlayerHasWeaponInSlot
	@summary
					    - Check if a player has a weapon in the slot
    @return
]]
local function checkPlayerHasWeaponInSlot(player: Player, weaponSlot: string)
    local _stored = Weapon.StoredPlayerInventories[player.Name]
    if not _stored then warn("Could not find stored player weapon inventory") return false end
    if _stored[weaponSlot] then
        return _stored[weaponSlot]
    end
    return false
end

local function setPlayerWeaponInSlot(player: string, weaponName: string, weaponSlot: string, weaponTool: Model)
    local _stored = Weapon.StoredPlayerInventories[player.Name]
    if not _stored then warn("Could not find stored player weapon inventory") return false end
    Weapon.StoredPlayerInventories[player.Name][weaponSlot] = {Name = weaponName, Tool = weaponTool, Slot = weaponSlot}
    return true
end

local function initToolAndModels(weaponName: string, weaponObjects: Folder) -- -> ClientModel, ServerModel
    local serverModel
	local clientModel
    local tool
    local model

    tool = Instance.new("Tool")
	tool.RequiresHandle = false
	tool.Name = "Tool_" .. weaponName

	model = weaponObjects.models.default
	
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

    return tool, clientModel, serverModel
end

local function initScripts(tool, isKnife)
    local clientScript, serverScript
    local newFolder = Instance.new("Folder") -- create folder
    newFolder.Name = "Scripts"

	clientScript = WeaponScripts[1]:Clone()
	serverScript = WeaponScripts[2]:Clone()

    clientScript.Parent, serverScript.Parent = newFolder, newFolder
    newFolder.Parent = tool
    return clientScript, serverScript, newFolder
end

local function initRemotesAndObjects(player, tool, clientModel, weaponObjects)
    -- remotes
    local weaponRemote = Instance.new("RemoteFunction")
	weaponRemote.Name = "WeaponRemoteFunction"
	weaponRemote.Parent = tool
	local weaponRemoteEvent = Instance.new("RemoteEvent")
	weaponRemoteEvent.Name = "WeaponRemoteEvent"
	weaponRemoteEvent.Parent = tool
	
    -- objects
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
	WeaponObjectsFolderObject.Value = weaponObjects
	WeaponObjectsFolderObject.Parent = tool
end

--[[@title 			    - Add
	@summary
					    - Adds a weapon to a player's inventory

    @return
]]
function Weapon.Add(player: Player, weaponName: string, forceEquip: boolean)

    -- init some check var
    local weaponObjects: Folder?
    local weaponOptions: ModuleScript?

    -- some weapon var
    local inventorySlot: string

    local serverModel
	local clientModel
	local serverScript
	local clientScript
    local scriptsFolder
    local tool
    local isKnife

    -- sanity checks
	if not player.Character then return false end

	weaponOptions, weaponObjects, isKnife = verifyWeaponSanity(weaponName)
    if not weaponOptions then return false end

	inventorySlot = weaponOptions.inventorySlot
	
    -- check if player has a weapon in the slot
	task.wait()
    local currentWeaponInSlot = checkPlayerHasWeaponInSlot(player, inventorySlot)
    if currentWeaponInSlot then
        Weapon.Remove(player, currentWeaponInSlot)
    end

	-- create tool & models
    tool, clientModel, serverModel = initToolAndModels(weaponName, weaponObjects)

	-- set player inv
    setPlayerWeaponInSlot(player, weaponName, inventorySlot, tool)
    
    -- init scripts
	clientScript, serverScript, scriptsFolder = initScripts(tool, isKnife)
	
	-- init remotes
	initRemotesAndObjects(player, tool, clientModel, weaponObjects)

	-- grab core functioncontainer
	local baseCore = WeaponScripts[1].Parent.basecore
	local core = WeaponScripts[1].Parent:FindFirstChild(string.lower(weaponName) .. "core")

	if core then
		core = core:Clone()
		core.Name = "corefunctions"
		core.Parent = clientScript
	end
	
	baseCore = baseCore:Clone()
	baseCore.Name = "basecorefunctions"
	baseCore.Parent = clientScript

    -- parent tool and enable scripts
	tool.Parent = player.Backpack
	serverScript.Enabled = true
	
	-- Add Weapon Client
	WeaponAddRemoveEvent:FireClient(player, "Add", weaponName, weaponOptions, weaponObjects)

	task.wait()
	task.wait()

	-- force equip
	if forceEquip then
		player.Character:WaitForChild("Humanoid"):EquipTool(tool)
	end

    return tool
end

--[[@title 			    - Remove
	@summary
					    - Removes a weapon from a players inventory

    @return
]]
function Weapon.Remove(player, weaponTable)
	if not player.Character then return end

	local tool = weaponTable.Tool
	WeaponAddRemoveEvent:FireClient(player, "Remove", tool)
	tool:Destroy()

	-- equip knife if possible
	local knife = checkPlayerHasWeaponInSlot(player, "ternary")
	if knife then
		if not knife or not knife.Parent then return end
		player.Character.Humanoid:EquipTool(knife.Tool)
	end

	-- set inv slot
	Weapon.StoredPlayerInventories[player.Name][weaponTable.Slot] = nil

end

function Weapon.ClearPlayerInventory(player)
	local currentInventory = Weapon.StoredPlayerInventories[player.Name]
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