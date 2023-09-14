local UserInputService = game:GetService("UserInputService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData
local RBXSignals = require(Framework.Module.lib.fc_rbxsignals)
local UIStates
local PlayerDied = game.ReplicatedStorage:WaitForChild("main").sharedMainRemotes.deathBE

export type WeaponVariables = {firing: boolean, reloading: boolean, equipped: boolean, equipping: boolean}
local WeaponVariables = {}
function WeaponVariables.new() return {firing = false, reloading = false, equipped = false, equipping = false} :: WeaponVariables end

export type WeaponControllerWeapon = {
    Name: string,
    Tool: Tool,
    ClientModel: Model,
    Slot: string,
    Variables: WeaponVariables,
    Remove: () -> (),
    Options: table,
    CoreFunctions: table
}

export type WeaponControllerOptions = {
    ResetInventoryOnDeath: boolean,
    CanEquipWeapons: boolean,

    primaryKey: string,
    secondaryKey: string,
    ternaryKey: string
}
local WeaponControllerOptions = {}
function WeaponControllerOptions.new(prop)
    local _op = {ResetInventoryOnDeath = true, CanEquipWeapons = true, primaryKey = "One", secondaryKey = "Two", ternaryKey = "Three"} :: WeaponControllerOptions
    if prop then
        for i, v in pairs(prop) do
            _op[i] = v
        end
    end
    return _op :: WeaponControllerOptions
end

export type WeaponController = {
    Owner: Player,
    Inventory: {primary: WeaponControllerWeapon | boolean, secondary: WeaponControllerWeapon | boolean, ternary: WeaponControllerWeapon | boolean},
    EquippedWeapon: string | false,
    Options: WeaponControllerOptions,
    Variables: table,

    Connect: (table) -> (),
    Disconnect: (table) -> (),
    ConnectActions: (()->(), ()->()) -> (),
    DisconnectActions: () -> (),

    AddWeapon: (table, string) -> boolean,
    RemoveWeapon: (table, string) -> boolean,

    ControllerEquip: (table) -> boolean,
    ControllerUnequip: (table) -> boolean,
    
    GetInventoryWeaponByName: WeaponControllerWeapon?,
    GetEquippedWeapon: WeaponControllerWeapon?,
    ClearInventory: (table) -> (),
}

local controller = {}
controller.__index = controller

--#region Server Module

PlayerData = require(Framework.shm_clientPlayerData.Location)
UIStates = require(Framework.Module.shared.states.m_states).State("UI")

--#endregion

function controller.new(player, options)
    local _controller = {
        Owner = player,
        Inventory = {primary = false, secondary = false, ternary = false},
        EquippedWeapon = false,
        Options = WeaponControllerOptions.new(options),
        Variables = {equipDebounce = false}
    }
    _controller = setmetatable(_controller, controller)

    _controller:Init()
    _controller:Connect()

    return _controller :: WeaponController
end

-- initialize keybinds from datastore
function controller:Init()
    for slot, _ in pairs(self.Inventory) do
        self.Options[slot .. "Key"] = PlayerData:Get("options.keybinds." .. slot .. "Weapon")
    end
end

function controller:Connect()

    -- disconnect sanity
    if self.connections and #self.connections > 0 then
        self:Disconnect()
    end

    self.connections = {}

    -- equip
    self.connections.equip = UserInputService.InputBegan:Connect(function(input, gp)
        if self.Owner:GetAttribute("Typing") or UIStates:hasOpenUI() then return end
        if self.Variables.equipDebounce then return end

        self.Variables.equipDebounce = "init"
        
        -- check if it's an equip key
        for i, v in pairs(self.Options) do
            if string.match(tostring(v), input.KeyCode.Name) then
                self.Variables.equipDebounce = "wait"
                task.delay(0.13, function()
                    self.Variables.equipDebounce = false
                end)
                return self:ControllerEquip(string.gsub(i, "Key", ""))
            end
        end

        -- if we made it this far, just disable debounce
        if self.Variables.equipDebounce == "init" then
            self.Variables.equipDebounce = false
        end
    end)

    -- connect all keybind datatstore changed
    for slot, _ in pairs(self.Inventory) do
        self.connections[slot .. "KeyChanged"] = PlayerData:Changed("options.keybinds." .. slot .. "Weapon", function(newValue)
            self.Options[slot .. "Key"] = newValue
        end)
    end

    -- connect reset inv on death if necessary
    if self.Options.ResetInventoryOnDeath then
        self.connections.died = PlayerDied.Event:Connect(function()
            self:ClearInventory()
        end)
    end

    self = self :: WeaponController
end

function controller:Disconnect()
    RBXSignals.DisconnectAllIn(self.connections)
    self.connections = {}
end

--

function controller:AddWeapon(...)
    local weaponName, weaponOptions, _, tool, clientModel, forceEquip = ...
    self.Inventory[weaponOptions.inventorySlot] = {
        Name = weaponName,
        Tool = tool,
        ClientModel = clientModel,
        Variables = WeaponVariables.new(),
        Remove = function()
            self.Inventory[weaponOptions.inventorySlot] = nil
            -- destroy viewmodel model
            if self.Viewmodel and self.Viewmodel:FindFirstChild("Equipped") and #self.Viewmodel.Equipped:GetChildren() > 0 then
                self.Viewmodel.Equipped:GetChildren()[1]:Destroy()
                for i, v in pairs(self.Viewmodel.AnimationController:GetPlayingAnimationTracks()) do
                    v:Stop()
                end
            end
        end,
        Slot = weaponOptions.inventorySlot,
        Options = weaponOptions
    } :: WeaponControllerWeapon
    if forceEquip then
        task.delay(0.9, function()
            self:ControllerEquip(weaponOptions.inventorySlot, true)
        end)
    end
    return true
end

function controller:RemoveWeapon(weapon: string?) -- idk if WeaponName will be easiest here we'll see
    local wep = self:GetInventoryWeaponByName(weapon)
    if wep then
        wep.Remove()
    end
    return true
end

function controller:GetInventoryWeaponByName(weapon: string): WeaponControllerWeapon?
    for i, v: WeaponControllerWeapon? in pairs(self.Inventory) do
        if v and v.Name and v.Name == weapon then
            return v
        end
    end
    return false
end

function controller:ClearInventory()
    for i, v in pairs(self.Inventory) do
        if v and v.Name then
            self:RemoveWeapon(v)
        end
    end
end

function controller:GetEquippedWeapon()
    for i, v in pairs(self.Inventory) do
        if v and v.Name and (v.Variables.equipped or v.Variables.equipping) then return v end
    end
    return false
end

--

local util_vmParts = {"LeftLowerArm", "LeftUpperArm", "RightUpperArm", "RightLowerArm"}

-- Request Equip -> Request Unequip Equipped -> Set Equipped WeaponModel Transparency thru Coro, set VM Transparency normally
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

-- Request Unequip -> Set Unequipped WeaponModel Transparency thru Coro, set VM Transparency normally
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

function controller:ConnectActions(firedownCB, fireupCB, reloadCB)
    if self.actions then self:DisconnectActions() end

    self.actions = {}
    self.actions.down = UserInputService.InputBegan:Connect(function(input, gp)
        if self.Owner:GetAttribute("Typing") or UIStates:hasOpenUI() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            firedownCB()
        elseif input.KeyCode == Enum.KeyCode.R then
            reloadCB()
        end
    end)

    self.actions.up = UserInputService.InputEnded:Connect(function(input, gp)
        if self.Owner:GetAttribute("Typing") or UIStates:hasOpenUI() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            fireupCB()
        end
    end)
end

function controller:DisconnectActions()
    if not self.actions then return end
    for i, v in pairs(self.actions) do
        v:Disconnect()
    end
    self.actions = nil
end

-- Equip a weapon from the controller by slot
-- To be executed from the WeaponController
function controller:ControllerEquip(slot, isForceEquip)

    if not self.Owner.Character or not self.Owner.Character.Humanoid or self.Owner.Character.Humanoid.Health <= 0 then return end
    if self.EquippedWeapon and self.EquippedWeapon.Slot == slot then return end
    if not self.Inventory[slot] then warn("Player trying to equip non existent weapon within the weapon controller") return end
    if self.Inventory[slot].Variables.equipped or self.Inventory[slot].Variables.equipping then return end

    if self.EquippedWeapon then
        util_processUnequipTransparency(self.EquippedWeapon.ClientModel)
    end
    task.wait()

    self.Owner.Character.Humanoid:UnequipTools()

    local a: Animator = workspace.CurrentCamera.viewModel.AnimationController.Animator
    for i, v in pairs(a:GetPlayingAnimationTracks()) do
        v:Stop()
    end

    task.wait()

    self.EquippedWeapon = self.Inventory[slot]
    self.Inventory[slot].Variables.equipping = true

    -- connect fire and reload
    self:ConnectActions(self.EquippedWeapon.CoreFunctions.firedown, self.EquippedWeapon.CoreFunctions.fireup, self.EquippedWeapon.CoreFunctions.reload)

    --Resolve:
    --Current Parent = Null New Parent bug
    if not self.Inventory[slot].Tool.Parent then
        repeat task.wait() until self.Inventory[slot].Tool.Parent
    end

    if isForceEquip then
        self.Inventory[slot].Tool:SetAttribute("IsForceEquip", true)
    end
    
    self.Owner.Character.Humanoid:EquipTool(self.Inventory[slot].Tool)

    task.delay(0.1, function()
        util_processEquipTransparency(self.EquippedWeapon.ClientModel)
    end)

    task.delay(self.Inventory[slot].Options.equipLength, function()
        if self.EquippedWeapon.Slot == slot then
            self.Inventory[slot].Variables.equipped = true
            self.Inventory[slot].Variables.equipping = false
        end
    end)

end

-- Unequip a weapon from the controller by slot
-- To be executed from the base_client script
function controller:ControllerUnequip(slot)
    
    if not self.Owner.Character or not self.Owner.Character.Humanoid or self.Owner.Character.Humanoid.Health <= 0 then return end
    if self.EquippedWeapon and self.EquippedWeapon.Slot ~= slot then return end
    if not self.Inventory[slot] then warn("Player trying to unequip non existent weapon within the weapon controller") return end

    self:DisconnectActions()
    self.EquippedWeapon = false
    self.Inventory[slot].Variables.equipping = false
    self.Inventory[slot].Variables.equipped = false

end

return controller