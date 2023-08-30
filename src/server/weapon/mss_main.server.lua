local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Weapon = require(Framework.Weapon.Location)
local WeaponModuleLoc = Framework.Weapon.Location
local WeaponRemotes = game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("remote")
local WeaponAddRemoveEvent = WeaponRemotes:WaitForChild("addremove")
local WeaponGetEvent = WeaponRemotes:WaitForChild("get")
local WeaponReplicateEvent = WeaponRemotes:WaitForChild("replicate")
local WeaponGetServerFunc = WeaponRemotes:WaitForChild("serverget")

-- [[ INVENTORY ]]
local function playerAdded_initInventory(player)
    Weapon.StoredPlayerInventories[player.Name] = {primary = nil, secondary = nil, ternary = nil}
end

local function playerRemoving_destroyInventory(player)
    Weapon.StoredPlayerInventories[player.Name] = nil
end

--[[ PLAYER ]]
function defaultCharAdded(player, char)
end

function defaultHumDied(player, char, hum)
end

-- [[ CONNECT ]]
Players.PlayerAdded:Connect(function(plr)
    
    -- inventory
    playerAdded_initInventory(plr)
    print("INITIALIZED " .. plr.Name .. " INVENTORY")

    -- char, died
    --[[plr.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid")
        defaultCharAdded(plr, char)

        hum.Died:Once(function()
            defaultHumDied(plr, char, hum)
        end)
    end)]]
end)

Players.PlayerRemoving:Connect(function(plr)
    playerRemoving_destroyInventory(plr)
end)

-- Connect Weapon Events
WeaponAddRemoveEvent.OnServerEvent:Connect(function(player, action, ...)
	if action == "Add" then
		Weapon.Add(player, ...)
	elseif action == "Remove" then
		Weapon.Remove(player, ...)
    end
end)

WeaponGetEvent.OnServerInvoke = function(player, action, ...)
	if action == "Options" then
		local weaponOptions = WeaponModuleLoc.Parent.config:FindFirstChild(string.lower(...))
		if not weaponOptions then
			return false
		end
		
		return require(weaponOptions)
	elseif action == "CameraRate" then
		return require(WeaponModuleLoc.Parent.config.camera).updateRate
	elseif action == "FireCameraDownWait" then
		return require(WeaponModuleLoc.Parent.config.camera).fireDownWaitLength
    elseif action == "GetRegisteredWeapons" then
		return Weapon:GetRegisteredWeapons()
	end
end

WeaponReplicateEvent.OnServerEvent:Connect(function(player, functionName, ...)
	for i, v in pairs(game:GetService("Players"):GetPlayers()) do
		if v == player then continue end
		WeaponReplicateEvent:FireClient(v, functionName, ...)
	end
end)