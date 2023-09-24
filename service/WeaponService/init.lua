local Players = game:GetService("Players")
if game:GetService("RunService"):IsClient() then return require(script:WaitForChild("Client")) end

local WeaponService = {}
local Weapons = script:WaitForChild("Weapon")
local WeaponTool = require(script:WaitForChild("WeaponTool"))
local RemoteEvent = script:WaitForChild("Events").RemoteEvent

WeaponService._Connections = {}
WeaponService._PlayerData = {}

function WeaponService:Start()
    WeaponService._Connections.RemoteEvent = RemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        if action == "AddWeapon" then
            -- do some middleware shit
            self:AddWeapon(player, ...)
        elseif action == "RemoveWeapon" then
            -- do some middleware shit
            self:RemoveWeapon(player, ...)
        end
    end)
    WeaponService._Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        self:InitPlayer(player)
    end)
end

function WeaponService:InitPlayer(player)
    if not WeaponService._PlayerData[player.Name] then
        WeaponService._PlayerData[player.Name] = {primary = false, secondary = false, ternary = false}
    end
end

--

function WeaponService:AddWeapon(player: Player, weapon: string, forceEquip: boolean?)
    if not player.Character then return false end

    local weaponModule = WeaponService:GetWeaponModule(weapon)
    if not weaponModule then
        warn("WeaponService: Cannot add weapon " .. tostring(weapon) .. " WeaponModule not found.")
        return false
    end

    -- server inventory management
    local weaponSlot = require(weaponModule).Configuration.inventorySlot
    if WeaponService:GetPlayerInventorySlot(player, weaponSlot) then
        print('yup server pre')
        WeaponService:RemoveWeapon(player, weaponSlot)
    end

    -- finalize tool
    local weaponTool = WeaponTool.new(player, weaponModule)
    if forceEquip then weaponTool:SetAttribute("IsForceEquip", true) end
    weaponTool.Parent = player.Backpack

    -- finalize server inventory
    WeaponService:SetPlayerInventoryWeaponFromSlot(player, weaponTool, weaponSlot)

    -- now the client side of weapon creation should happen via weaponTool WeaponClient
    return true
end

function WeaponService:RemoveWeapon(player: Player, slot: string)
    if not player.Character then return end
    local weapon = WeaponService:GetPlayerInventorySlot(player, slot)
    print('yup server pre post')
    if not weapon then return end
    print('yup server post')
    RemoteEvent:FireClient(player, "RemoveWeapon", slot)
    print('yup server event')
    task.delay(1/60, function()
        weapon:Destroy()
        WeaponService:SetPlayerInventoryWeaponFromSlot(player, false, slot)
    end)
end

--

function WeaponService:GetWeaponModule(weapon: string)
    local module = false
    for i, v in pairs(Weapons:GetChildren()) do
        if string.lower(weapon) == string.lower(v.Name) then
            module = v
            break
        end
    end
    return module
end

function WeaponService:GetWeaponNameFromTool(tool: Tool)
    return tool.Name:gsub("Tool_", "")
end

function WeaponService:SetPlayerInventoryWeaponFromSlot(player: Player, weapon: Tool | false, slot: string)
    WeaponService._PlayerData[player.Name][slot] = weapon
end

function WeaponService:GetPlayerInventorySlot(player, slot)
    if not WeaponService._PlayerData[player.Name] then warn("No PlayerData for player " .. player.Name) WeaponService:InitPlayer(player) end
    return WeaponService._PlayerData[player.Name][slot] or false
end

--[[function Weapon.ClearAllPlayerInventories()
	for _, player in pairs(Players:GetPlayers()) do
		Weapon.ClearPlayerInventory(player)
	end
end]]

function WeaponService:GetRegisteredWeapons()
	local wep = {}
	for i, v in pairs(Weapons:GetChildren()) do
		if v:GetAttribute("Ignore") then continue end
		table.insert(wep, v.Name)
	end
	return wep
end

--[[function Weapon:GetRegisteredWeaponOptions()
	local wep = {}
	for i, v in pairs(ServerScriptService.weapon.config:GetChildren()) do
		if v:GetAttribute("Ignore") then continue end
		wep[v.Name] = v
	end
	return wep
end]]

return WeaponService