--[[

    WeaponController Class

    Create a WeaponController for a Player.
    Automatically deletes when player dies.

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
if RunService:IsServer() then return end

local WeaponController = {}
WeaponController.__index = WeaponController
WeaponController.CurrentController = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Types = require(script:WaitForChild("Types"))
local Tables = require(Framework.Module.lib.fc_tables)
local PlayerDiedBind = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathBE")
local UserInputService = game:GetService("UserInputService")
local PlayerData = require(Framework.Module.shared.playerdata.m_clientPlayerData)
local Remote = ReplicatedStorage.Modules.WeaponController2.Remote
local UIState = require(Framework.Module.shared.states.m_states).State("UI")

--[[ CONFIGURATION ]]
local ForceEquipDelay = 0.9
local EquipInputDebounce = 0.04
local NeededKeybindKeys = {"primaryWeapon", "secondaryWeapon", "ternaryWeapon", "inspect", "drop"}

local self = {}
self.Inventory = {equipped = false, primary = false, secondary = false, ternary = false}
self.Connections = {}
self.Owner = Players.LocalPlayer
self.Processing = false
self.CanEquip = true
self.BaseInputDebounce = tick()
self.InitialWeaponAddDebounce = false
self = setmetatable(self, WeaponController) :: Types.WeaponController
self.CurrentController = nil

-- init keybinds
local playerOptions = PlayerData:Get("options.keybinds")
self.Keybinds = {}

for i, v in pairs(Tables.clone(NeededKeybindKeys)) do

    -- init bind key
    self.Keybinds[v] = playerOptions[v]
    table.remove(self.Keybinds, i)

    -- init bind changed
    self.Connections["KeybindChanged_" .. v] = PlayerData:Changed("options.keybinds." .. v, function(new)
        self.Keybinds[v] = new
    end)
end

self.PlayerDiedConnect = PlayerDiedBind.Event:Connect(function()
    self:Remove()
end)

self.Connections.BaseInput = UserInputService.InputBegan:Connect(function(input, gp)
    self:WeaponControllerBaseInputBegan(input, gp)
end)

self.Connections.RemoveWeapon = Remote.OnClientEvent:Connect(function(action, weaponSlot)
    if action == "RemoveWeapon" then
        if self.Inventory[weaponSlot] then
            self.Inventory[weaponSlot].Remove()
        end
    end
end)

--@summary Disconnect the Connections of a WeaponController. (Cannot undo)
function WeaponController:Disconnect()
    for _, v in pairs(self.Connections) do
       v:Disconnect()
    end
    self:ClearInventory()
end

--@summary Remove the WeaponController
function WeaponController:Remove()
    self:Disconnect()
    WeaponController.CurrentController = false
    self.PlayerDiedConnect:Disconnect()
    self = nil
end

--

--@summary Add a Weapon to the Controller
function WeaponController:AddWeapon(weaponName, weaponOptions, _, tool, clientModel, forceEquip, actionFunctions)
    self.CanEquip = false
    self.Processing = true

    if self.Inventory[weaponOptions.inventorySlot] then
        self.Inventory[weaponOptions.inventorySlot].Remove()
    end

    local weapon = {
        Name = weaponName,
        Tool = tool,
        ClientModel = clientModel,
        Slot = weaponOptions.inventorySlot,
        Options = weaponOptions,
        ActionFunctions = actionFunctions,
        IsKnife = string.lower(weaponName) == "knife",

        Connections = {
            Unequip = tool.Unequipped:Connect(function()
                self:UnequipWeapon(weaponOptions.inventorySlot)
            end)
        },

    } :: Types.Weapon

    weapon.ConnectActions = function()
        if not self.Inventory[weaponOptions.inventorySlot] then warn("Cant connect non-existent weapon.") return end
        self.Inventory[weaponOptions.inventorySlot].Connections.Down = UserInputService.InputBegan:Connect(function(input, gp)
            self:WeaponActionInputBegan(weapon, input, gp)
        end)
        self.Inventory[weaponOptions.inventorySlot].Connections.Up = UserInputService.InputEnded:Connect(function(input, gp)
            self:WeaponActionInputEnded(weapon, input, gp)
        end)
    end

    weapon.DisconnectActions = function()
        if not self.Inventory[weaponOptions.inventorySlot] then return end
        for i, v in pairs(self.Inventory[weaponOptions.inventorySlot].Connections) do
            if i == "Unequip" then continue end
           v:Disconnect()
        end
    end

    weapon.Remove = function()
        weapon.DisconnectActions()
        if self.Inventory.equipped then
            if self.Inventory.equipped.Name == weaponName then
                self.Owner.Character.Humanoid:UnequipTools()
                task.wait()
            end
        end
        if self.Inventory[weaponOptions.inventorySlot] and self.Inventory[weaponOptions.inventorySlot].Connections then
            for i, v in pairs(self.Inventory[weaponOptions.inventorySlot].Connections) do
                v:Disconnect()
            end
        end
        self.Inventory[weaponOptions.inventorySlot] = nil
    end

    self.Inventory[weaponOptions.inventorySlot] = weapon

    if forceEquip then
        self.InitialWeaponAddDebounce = true
        task.delay(ForceEquipDelay, function()
            self.CanEquip = true
            self.Processing = false
            self.InitialWeaponAddDebounce = false
            self:EquipWeapon(weaponOptions.inventorySlot, true)
        end)
        return true
    end

    self.Processing = false
    self.CanEquip = true
    return true
end

--@summary Remove a Weapon from the Controller
function WeaponController:RemoveWeapon(weaponSlot)
    self.Inventory[weaponSlot].Remove()
end

--@summary Remove all Weapons from the Controller
function WeaponController:ClearInventory()
    for _, v in pairs(self.Inventory) do
        if v then v.Remove() end
    end
end

--

--@summary Equip a Weapon via slot. Called when a player presses the corresponding equip key.
function WeaponController:EquipWeapon(weaponSlot, bruteForce)
    if not bruteForce and (not self.CanEquip) then return warn("canequip or processing, equip:", tostring(self.CanEquip), tostring(self.Processing)) end
	if not self.Owner.Character or not self.Owner.Character.Humanoid or self.Owner.Character.Humanoid.Health <= 0 then return end
    if not bruteForce and self.Inventory.equipped and self.Inventory.equipped.Slot == weaponSlot then return warn(tostring(weaponSlot) .. " is already equipped") end
    if not self.Inventory[weaponSlot] then local t = tick() + 3 repeat task.wait() until self.Inventory[weaponSlot] or tick() >= t end
    if not self.Inventory[weaponSlot] then return warn(tostring(weaponSlot) .. " not found in inv") end
    if self.InitialWeaponAddDebounce then return end

    self.CanEquip = false

    if self.Inventory.equipped then
        util_processUnequipTransparency(self.Inventory.equipped.ClientModel)
    end
    --task.wait()
    self.Owner.Character.Humanoid:UnequipTools()

    task.spawn(function()
        local a: Animator = workspace.CurrentCamera.viewModel.AnimationController.Animator
        for i, v in pairs(a:GetPlayingAnimationTracks()) do
            v:Stop()
        end
    end)

    task.wait()

    self.Inventory.equipped = self.Inventory[weaponSlot]
    self.Inventory.equipped.ConnectActions() -- connect weapon actions here

    --Resolve:
    --Current Parent = Null New Parent bug
    if not self.Inventory[weaponSlot].Tool.Parent then
        repeat task.wait() until self.Inventory[weaponSlot].Tool.Parent
    end

    --[[if isForceEquip then
        self.Inventory[slot].Tool:SetAttribute("IsForceEquip", true)
    end]]
    
    self.Owner.Character.Humanoid:EquipTool(self.Inventory.equipped.Tool)

    task.delay(0.1, function()
        util_processEquipTransparency(self.Inventory.equipped.ClientModel)
    end)

    self.Processing = false
    self.CanEquip = true
end

--@summary Unequip a Weapon via slot. Called in tool.Unequipped
function WeaponController:UnequipWeapon(weaponSlot)
    self.Inventory[weaponSlot].DisconnectActions()
    if not self.Owner.Character or not self.Owner.Character.Humanoid or self.Owner.Character.Humanoid.Health <= 0 then return end
    if self.Inventory.equipped == self.Inventory[weaponSlot] then
        self.Inventory.equipped = false
    end
end

--@summary Get the Currently Equipped Weapon
function WeaponController:GetEquippedWeapon()
    return self.Inventory.equipped
end

--

--@summary Listen for Equip input. Always connected.
function WeaponController:WeaponControllerBaseInputBegan(input, gp)
    if UIState:hasOpenUI() or gp then return end
    if tick() < self.BaseInputDebounce then
        return
    end
    self.BaseInputDebounce = tick() + EquipInputDebounce

    for _, slot in pairs({"primary", "secondary", "ternary"}) do
        local kc = false
        pcall(function() kc = input.KeyCode == Enum.KeyCode[self.Keybinds[slot .. "Weapon"]] end)
        if kc then
            self:EquipWeapon(slot)
            self.Processing = true
            return
        end
    end

    if not self.Processing then
        self.BaseInputDebounce = 0 -- reset debounce if nothing is happening
    end
end

--@summary Listen for Action (Fire, Reload, Inspect, etc) input. Only connected when equipped.
function WeaponController:WeaponActionInputBegan(weapon: Types.Weapon, input, gp)
    if UIState:hasOpenUI() or gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        weapon.ActionFunctions.firedown()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        weapon.ActionFunctions.secondaryfiredown()
    elseif input.KeyCode == Enum.KeyCode.R then
        weapon.ActionFunctions.reload()
    elseif input.KeyCode == Enum.KeyCode[self.Keybinds.inspect] then
        weapon.ActionFunctions.startinspect()
    end
    task.wait()
end

--@summary Listen for Action (Fire, SecondaryFire) input ended. Only connected when equipped.
function WeaponController:WeaponActionInputEnded(weapon: Types.Weapon, input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
        weapon.ActionFunctions.fireup()
    end
end

--

local util_vmParts = {"LeftLowerArm", "LeftUpperArm", "RightUpperArm", "RightLowerArm"}

--@summary Request Equip -> Request Unequip Equipped -> Set Equipped WeaponModel Transparency thru Coro, set VM Transparency normally
function util_processEquipTransparency(model)
    local vm = workspace.CurrentCamera:FindFirstChild("viewModel")
    if not vm then return end

    for i, v in pairs(model:GetDescendants()) do
        if v.Name == "WeaponHandle" or v.Name == "WeaponTip" then continue end

        if v:IsA("MeshPart") or v:IsA("Part") or v:IsA("Texture") then
            v.Transparency = v:GetAttribute("Transparency") or 0
        end
    end

    for i, v in pairs(util_vmParts) do
        vm[v].Transparency = 0
    end

    vm.RightHand.RightGlove.Transparency = 0
    vm.LeftHand.LeftGlove.Transparency = 0
end

--@summary Request Unequip -> Set Unequipped WeaponModel Transparency thru Coro, set VM Transparency normally
function util_processUnequipTransparency(model)
    local vm = workspace.CurrentCamera:FindFirstChild("viewModel")
    if not vm then return end

    task.spawn(function()
        for i, v in pairs(util_vmParts) do
            vm[v].Transparency = 1
        end
    end)

    for i, v in pairs(model:GetDescendants()) do
        task.spawn(function()
            if v.Name == "WeaponHandle" or v.Name == "WeaponTip" then return end

            if v:IsA("MeshPart") or v:IsA("Part") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end)
    end

    vm.RightHand.RightGlove.Transparency = 1
    vm.LeftHand.LeftGlove.Transparency = 1
end

-- @SCRIPT_START

WeaponController.CurrentController = self
require(script:WaitForChild("Interface"))._init(self)