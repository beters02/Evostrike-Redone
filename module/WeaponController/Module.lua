local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- This is the API wrapper for the WeaponController.
local WeaponController = {}
WeaponController.Remote = script.Parent.Remote
WeaponController.ModuleConnected = false
WeaponController.ModuleConnecting = false
WeaponController.Class = script.Parent.Class

--[[ Shared ]]

function WeaponController:AddWeapon(player: Player, yield: number?, ...)
    if not self:HasWeaponController(player) then
        local hasController = false
        if yield then
            local _to = tonumber(yield) or 3
            repeat task.wait(1) hasController = self:HasWeaponController(player) until hasController or tick() >= _to -- don't be cloggin them remote queues up lmao
        end
        if not hasController then
            return error("Player does not have a WeaponController!")
        end
    end

    if RunService:IsServer() then
        return WeaponController.Remote:InvokeClient(player, "AddWeapon", yield, ...)
    end

    return self.StoredWeaponController:AddWeapon(...)
end

function WeaponController:RemoveWeapon(player: Player, yield: number?, weapon: string)
    if not self:HasWeaponController(player) then
        local hasController = false
        if yield then
            local _to = tonumber(yield) or 3
            repeat task.wait(1) hasController = self:HasWeaponController(player) until hasController or tick() >= _to -- don't be cloggin them remote queues up lmao
        end
        if not hasController then
            return error("Player does not have a WeaponController!")
        end
    end

    if RunService:IsServer() then
        return WeaponController.Remote:InvokeClient(player, "RemoveWeapon", weapon)
    end

    return self.StoredWeaponController:RemoveWeapon(yield, weapon)
end

function WeaponController:HasWeaponController(player: Player?)
    if RunService:IsServer() then
        return WeaponController.Remote:InvokeClient(player, "HasWeaponController")
    end

    return self.StoredWeaponController or false
end

--[[ Server ]]
if RunService:IsServer() then
    WeaponController.ModuleConnected = true
end

--[[ Client ]]
if RunService:IsClient() then

    if type(WeaponController.Class) ~= "table" then
        WeaponController.Class = require(WeaponController.Class)
    end

    -- Required for Add/Remove
    function WeaponController:Listen()
        if not WeaponController.ModuleConnected and not WeaponController.ModuleConnecting then
            WeaponController.ModuleConnecting = true
            WeaponController.Remote.OnClientInvoke = function(action, ...)
                local _to = tick() + 5
                repeat task.wait() until self.StoredWeaponController or tick() >= _to
                if not self.StoredWeaponController then
                    return error("Must add WeaponController to do this action")
                end
                local result
                local p = table.pack(...)
                result = self[action](self, Players.LocalPlayer, table.unpack(p))
                return result
            end
            WeaponController.Connected = true
            WeaponController.ModuleConnecting = false
        end
    end

    -- Disconnect from Add/Remove
    function WeaponController:Disconnect()
        WeaponController.Remote.OnClientInvoke = nil
    end

    -- Add Controller
    function WeaponController:AddWeaponController(player, options, destroyPrevious)
        if WeaponController:HasWeaponController() then
            if not destroyPrevious then
                return self.StoredWeaponController
            end

            self:RemoveWeaponController()
        end

        local _wc = WeaponController.Class.new(player, options)
        self.StoredWeaponController = _wc
        return self.StoredWeaponController
    end

    -- Remove Controller
    function WeaponController:RemoveWeaponController()
        if not self:HasWeaponController() then
            return warn("No WeaponController to remove.")
        end

        self.StoredWeaponController:Disconnect()
        self.StoredWeaponController = nil
    end

    -- Equip a Weapon from your inventory
    function WeaponController:Equip(slot)
        self.StoredWeaponController:ControllerEquip(slot)
    end

    -- Unequip a weapon from your inventory
    function WeaponController:Unequip(slot)
        self.StoredWeaponController:ControllerUnequip(slot)
    end

end

return WeaponController