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
local Types = require(script.Parent:WaitForChild("Types"))
local Tables = require(Framework.Module.lib.fc_tables)
local PlayerDiedBind = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathBE")
local UserInputService = game:GetService("UserInputService")
local PlayerData = require(Framework.Module.shared.playerdata.m_clientPlayerData)
local Remote = ReplicatedStorage.Modules.WeaponController2.Remote
local UIState = require(Framework.Module.shared.states.m_states).State("UI")
local Weapon = require(game:GetService("ReplicatedStorage").Services.WeaponService.Weapon)

--[[ CONFIGURATION ]]
local ForceEquipDelay = 0.9
local EquipInputDebounce = 0.04
local NeededKeybindKeys = {"primaryWeapon", "secondaryWeapon", "ternaryWeapon", "inspect", "drop", "equipLastEquippedWeapon"}
local util_vmParts = {"LeftLowerArm", "LeftUpperArm", "RightUpperArm", "RightLowerArm"}

function WeaponController.new()
    local self = {}
    self.Inventory = {equipped = false, last_equipped = false, primary = false, secondary = false, ternary = false}
    self.Connections = {}
    self.Owner = Players.LocalPlayer
    self.Humanoid = self.Owner.Character:WaitForChild("Humanoid")
    self.Processing = false
    self.CanEquip = true
    self.BaseInputDebounce = tick()
    self.InitialWeaponAddDebounce = false
    self.CurrentController = nil
    self.MovementCommunicate = require(self.Owner.Character:WaitForChild("MovementScript"):WaitForChild("Communicate"))

    self.GroundMaxSpeed = self.MovementCommunicate.GetVar("groundMaxSpeed")

    -- init keybinds
    local playerOptions = PlayerData:Get("options.keybinds")
    self.Keybinds = {}
    for i, v in pairs(Tables.clone(NeededKeybindKeys)) do
        self.Keybinds[v] = playerOptions[v]
        table.remove(self.Keybinds, i)
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

    return setmetatable(self, WeaponController) :: Types.WeaponController
end

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

--@summary Add a Weapon to the Controller (must have been created on the server first)
function WeaponController:AddWeapon(weapon: string, tool: Tool, forceEquip: boolean?)
    local wepObject: Types.Weapon = Weapon.new(weapon, tool)
    self.Inventory[wepObject.Slot] = wepObject

    if forceEquip then
        self.InitialWeaponAddDebounce = true
        task.delay(ForceEquipDelay, function()
            self.InitialWeaponAddDebounce = false
            self:EquipWeapon(wepObject.Slot, true)
        end)
        return true
    end

    return true
end

--@summary Remove a Weapon from the Controller
function WeaponController:RemoveWeapon(weaponSlot)
    if self.Inventory.equipped.Slot == weaponSlot then
        self.Humanoid:UnequipTools()
    end
    self.Inventory[weaponSlot]:Remove()
end

--@summary Equip a Weapon via slot. Called when a player presses the corresponding equip key.
function WeaponController:EquipWeapon(weaponSlot, bruteForce)
    --if not bruteForce and (not self.CanEquip) then return warn("canequip or processing, equip:", tostring(self.CanEquip), tostring(self.Processing)) end
    --if not bruteForce and self.Inventory.equipped and self.Inventory.equipped.Slot == weaponSlot then return warn(tostring(weaponSlot) .. " is already equipped") end
	if not self.Owner.Character or not self.Owner.Character.Humanoid or self.Owner.Character.Humanoid.Health <= 0 then print('CHARACTER UNVERIFY')  return end
    if not self:IsWeaponInSlot(weaponSlot) then return warn("No weapon in slot " .. weaponSlot) end
    if not bruteForce and self:IsWeaponEquipped(weaponSlot) then print('ISEQUIPPED') return end
    if self.InitialWeaponAddDebounce then print('INITIAL DEBOUNCE')  return end

    -- last equipped
    if not self.Inventory.last_equipped then
        self.Inventory.last_equipped = self.Inventory[weaponSlot]
    end

    -- process unequip transparency early to resolve glitchy VM
    if self.Inventory.equipped then
        util_processUnequipTransparency(self.Inventory.equipped.ClientModel)
        self.Owner.Character.Humanoid:UnequipTools()
    end

    -- stop all vm animations? lets do this in a seperate function when we get a sec
    task.spawn(function()
        local a: Animator = workspace.CurrentCamera.viewModel.AnimationController.Animator
        for i, v in pairs(a:GetPlayingAnimationTracks()) do
            v:Stop()
        end
    end)

    task.wait()

    -- set inventory equipped
    self.Inventory.equipped = self.Inventory[weaponSlot]

    --Resolve:
    --Current Parent = Null New Parent bug
    if not self.Inventory[weaponSlot].Tool.Parent then
        repeat task.wait() until self.Inventory[weaponSlot].Tool.Parent
    end
    
    -- equip tool
    self.Owner.Character.Humanoid:EquipTool(self.Inventory.equipped.Tool)
    self.Inventory[weaponSlot]:ConnectActions()
    task.delay(0.1, function()
        util_processEquipTransparency(self.Inventory.equipped.ClientModel)
    end)
end

--@summary Unequip a Weapon via slot. Called in tool.Unequipped
function WeaponController:UnequipWeapon(weaponSlot)
    if not self.Owner.Character or not self.Owner.Character.Humanoid or self.Owner.Character.Humanoid.Health <= 0 then return end
    self.Inventory[weaponSlot]:DisconnectActions()
    self.Inventory[weaponSlot]:Unequip()

    if self.Inventory.equipped == self.Inventory[weaponSlot] then
        self.Inventory.equipped = false
    end
    self.Inventory.last_equipped = self.Inventory[weaponSlot]
end

--@summary Get the Currently Equipped Weapon
function WeaponController:GetEquippedWeapon()
    return self.Inventory.equipped
end

--@summary Check if a weapon is equipped
function WeaponController:IsWeaponEquipped(weaponSlot)
    return self.Inventory[weaponSlot] and (self.Inventory[weaponSlot].Variables.equipped or self.Inventory[weaponSlot].Variables.equipping) or false
end

function WeaponController:IsWeaponInSlot(weaponSlot)
    return self.Inventory[weaponSlot] and true or false
end

--@summary Remove all Weapons from the Controller
function WeaponController:ClearInventory()
    for _, v in pairs(self.Inventory) do
        if v then v:Remove() end
    end
end

-- Weapon Action Processing
-- These functions are ran on WeaponController to ensure no overriding functionality is happening

--@summary Listen for Equip input. Always connected.
function WeaponController:WeaponControllerBaseInputBegan(input, gp)
    if UIState:hasOpenUI() or gp then return end
    if tick() < self.BaseInputDebounce then return end

    if input.KeyCode == Enum.KeyCode[self.Keybinds.equipLastEquippedWeapon] then
        if not self.Inventory.last_equipped then return end
        self.BaseInputDebounce = tick() + EquipInputDebounce
        self:EquipWeapon(self.Inventory.last_equipped.Slot)
        return
    else
        for _, slot in pairs({"primary", "secondary", "ternary"}) do
            local kc = false
            pcall(function() kc = input.KeyCode == Enum.KeyCode[self.Keybinds[slot .. "Weapon"]] end)
            if kc then
                self.BaseInputDebounce = tick() + EquipInputDebounce
                self:EquipWeapon(slot)
                return
            end
        end
    end

    self.BaseInputDebounce = 0 -- reset debounce if nothing is happening
end

--@summary Handle the movement speed reduction given by a weapon
function WeaponController:HandleHoldMovementPenalty(slot: string, equip: boolean)
	local currAdd = self.MovementCommunicate.GetVar("maxSpeedAdd")
	if currAdd + self.GroundMaxSpeed > self.GroundMaxSpeed then
		currAdd = 0
	end

    local wep = self.Inventory[slot]

	if equip then
		currAdd -= wep.Options.movement.penalty
	else
		currAdd += wep.Options.movement.penalty
	end

	self.MovementCommunicate.SetVar("maxSpeedAdd", currAdd)
end

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

--@summary Stop all current vm animations
function WeaponController:_StopAllVMAnimations()
    for _, v in pairs(workspace.CurrentCamera.viewModel.AnimationController:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end

return WeaponController