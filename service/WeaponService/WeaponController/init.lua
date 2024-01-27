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
local PlayerDiedBind = Framework.Module.EvoPlayer.Events.PlayerDiedBindable
local UserInputService = game:GetService("UserInputService")
local PlayerData2 = require(Framework.Module.PlayerData)
local Remote = ReplicatedStorage.Services.WeaponService.Events.RemoteEvent
local UIState = require(Framework.Module.States):Get("UI")
local Weapon = require(game:GetService("ReplicatedStorage").Services.WeaponService.Weapon)
local VMSprings = require(Framework.Module.lib.c_vmsprings)

--[[ CONFIGURATION ]]
local ForceEquipDelay = 0.9
local EquipInputDebounce = 0.04
local NeededKeybindKeys = {"primaryWeapon", "secondaryWeapon", "ternaryWeapon", "bombWeapon", "inspect", "drop", "equipLastEquippedWeapon", "aimToggle"}
local util_vmParts = {"LeftLowerArm", "LeftUpperArm", "RightUpperArm", "RightLowerArm"}

--[[ EQUIP KEYBIND ACTIONS ]]
local BaseEquipKeybindActions = {
    equipLast = function(self)
        if not self.Inventory.last_equipped then return end
        self.BaseInputDebounce = tick() + EquipInputDebounce
        self:EquipWeapon(self.Inventory.last_equipped.Slot)
        return
    end,
    
    equipNew = function(self, slot)
        self.BaseInputDebounce = tick() + EquipInputDebounce
        self:EquipWeapon(slot)
    end
}

function WeaponController.new()
    local self = {}
    self.Inventory = {equipped = false, last_equipped = false, primary = false, secondary = false, ternary = false, bomb = false}
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

    util_initKeybinds(self)

    self = setmetatable(self, WeaponController)

    self.PlayerDiedConnect = PlayerDiedBind.Event:Connect(function()
        self:Remove()
    end)

    self.Connections.BaseInput = UserInputService.InputBegan:Connect(function(input, gp)
        self:WeaponControllerBaseInputBegan(input, gp)
    end)

    self.Connections.RemoveWeapon = Remote.OnClientEvent:Connect(function(action, weaponSlot)
        if action == "RemoveWeapon" then
            if self.Inventory[weaponSlot] then
                self.Inventory[weaponSlot]:Remove()
            end
        elseif action == "ClearInventory" then
            for i, v in pairs(self.Inventory) do
                if v then v:Remove() end
                self.Inventory[i] = false
            end
        end
    end)

    -- this is where we will do bomb observe update
    self.Connections.Update = RunService.RenderStepped:Connect(function(dt)
        -- is player looking at bomb?
        -- can player defuse bomb?
        for _, v in pairs(self.Inventory) do
            if v and v.EquipSpring then
                local pos = v.EquipSpring:update(dt)
                workspace.CurrentCamera.CFrame *= CFrame.Angles(math.rad(pos.X), math.rad(pos.Y), math.rad(pos.Z))
            end
        end
    end)

    return self
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
function WeaponController:AddWeapon(weapon: string, tool: Tool, forceEquip: boolean?, recoilScript)
    local wepObject: Types.Weapon = Weapon.new(weapon, tool, recoilScript)
    self.Inventory[wepObject.Slot] = wepObject

    local currentEquipSprThread = false
    local equipSpring = VMSprings:new(9, 50, 5, 5)
    local shoveVec = Vector3.new(1.4,0,0)
    wepObject.EquipSpring = equipSpring

    local function shoveEquip()
        local dt = wepObject._stepDT
        equipSpring:shove(shoveVec*dt*60)
        task.wait((1/60)*(dt/(1/60))*2)
        equipSpring:shove(-shoveVec*dt*60)
    end
    shoveEquip = wepObject.Options.equipSpringShoveFunction or shoveEquip

    wepObject.Connections.EquipAnim = wepObject.Tool.Equipped:Connect(function()
        if currentEquipSprThread then
            task.cancel(currentEquipSprThread)
        end
        currentEquipSprThread = task.spawn(function()
            shoveEquip(equipSpring, wepObject._stepDT)
        end)
    end)

    if forceEquip then
        self.InitialWeaponAddDebounce = true
        task.delay(ForceEquipDelay, function()
            self:EquipWeapon(wepObject.Slot, true)
        end)
        return wepObject
    end

    return wepObject
end

--@summary Remove a Weapon from the Controller
function WeaponController:RemoveWeapon(weaponSlot)
    if self.Inventory.equipped.Slot == weaponSlot then
        self.Humanoid:UnequipTools()
    end
    self.Inventory[weaponSlot]:Remove()
    RunService:UnbindFromRenderStep(weaponSlot .. "_CamRec")
end

--@summary Equip a Weapon via slot. Called when a player presses the corresponding equip key.
function WeaponController:EquipWeapon(weaponSlot, bruteForce)
    --if not bruteForce and (not self.CanEquip) then return warn("canequip or processing, equip:", tostring(self.CanEquip), tostring(self.Processing)) end
    --if not bruteForce and self.Inventory.equipped and self.Inventory.equipped.Slot == weaponSlot then return warn(tostring(weaponSlot) .. " is already equipped") end

    if not self.Owner.Character or not self.Owner.Character.Humanoid or self.Owner.Character.Humanoid.Health <= 0 then return end
    if not self:IsWeaponInSlot(weaponSlot) then return end
    if not bruteForce then
        if self:IsWeaponEquipped(weaponSlot) then return end
        if self.InitialWeaponAddDebounce then return end
    end
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
        if self.Inventory.equipped and self.Inventory.equipped.ClientModel then
            util_processEquipTransparency(self.Inventory.equipped.ClientModel)
        end
    end)

    self.InitialWeaponAddDebounce = false
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
    if gp or UIState:hasOpenUI()
    or not self.EquipKeybindActions[input.KeyCode.Name]
    or tick() < self.BaseInputDebounce then
        return
    end

    self.EquipKeybindActions[input.KeyCode.Name]()
end

--@summary Handle the movement speed reduction given by a weapon
function WeaponController:HandleHoldMovementPenalty(slot: string)
	local wep = self.Inventory[slot]
    self.MovementCommunicate.SetVar("equippedWeaponPenalty", wep.Options.movement.penalty)
end

--@summary Stop all current vm animations
function WeaponController:_StopAllVMAnimations()
    for _, v in pairs(workspace.CurrentCamera.viewModel.AnimationController:GetPlayingAnimationTracks()) do
        v = v :: AnimationTrack
		v:Stop()
	end
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

--@summary Initialize WeaponController Keybinds and Keybind Changed
function util_initKeybinds(self)
    local playerOptions = PlayerData2:GetPath("options.keybinds")
    self.Keybinds = {}             -- {Action = Key (string)}
    self.EquipKeybindActions = {}  -- {Key = Action (func)}

    -- convert primaryWeapon -> primary, for all equip keybinds
    for _, keyAction in pairs(NeededKeybindKeys) do
        local currKey = util_setKeybind(self, keyAction, false, false, playerOptions)
        self.Connections["KeybindChanged_" .. keyAction] = PlayerData2:PathValueChanged("options.keybinds." .. keyAction, function(new)
            currKey = util_setKeybind(self, keyAction, new, currKey, playerOptions)
        end)
    end
end

--@summary Set the keybind as new from old or get from playerOptions
function util_setKeybind(self, action, newKey, oldKey, playerOptions)
    local key = newKey or playerOptions[action]
    if action == "equipLastEquippedWeapon" then
        if oldKey then self.EquipKeybindActions[oldKey] = nil end
        self.EquipKeybindActions[key] = function() BaseEquipKeybindActions.equipLast(self) end
    elseif string.match(action, "Weapon") then
        if oldKey then self.EquipKeybindActions[oldKey] = nil end
        self.EquipKeybindActions[key] = function() BaseEquipKeybindActions.equipNew(self, string.gsub(action, "Weapon", "")) end
    end

    self.Keybinds[action] = key
    return key
end

return WeaponController