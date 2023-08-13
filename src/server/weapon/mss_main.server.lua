local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Weapon = require(Framework.Weapon.Location)

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

    -- char, died
    plr.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid")
        defaultCharAdded(plr, char)

        hum.Died:Once(function()
            defaultHumDied(plr, char, hum)
        end)
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    playerRemoving_destroyInventory(plr)
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local WeaponModuleLoc = Framework.Weapon.Location
local WeaponRemotes = game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("remote")
local WeaponAddRemoveEvent = WeaponRemotes:WaitForChild("addremove")
local WeaponGetEvent = WeaponRemotes:WaitForChild("get")
local WeaponReplicateEvent = WeaponRemotes:WaitForChild("replicate")
local WeaponGetServerFunc = WeaponRemotes:WaitForChild("serverget")

local store
local buffer

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
    end
end

WeaponReplicateEvent.OnServerEvent:Connect(function(player, functionName, ...)
	for i, v in pairs(game:GetService("Players"):GetPlayers()) do
		if v == player then continue end
		WeaponReplicateEvent:FireClient(v, functionName, ...)
	end
end)

-- LAG COMPENSATION TEST
local LagCompensationEnabled = false

WeaponGetServerFunc.OnInvoke = function(player, diff)
    if not LagCompensationEnabled then return false end
    local r = math.round(diff*100)
    local b = buffer + r
    if not store[b] then return false end
    return store[b].loc
end

local n = tick()
local tickRate = 1/32
local maxBuffer = 1024
store = {}
buffer = 1

local function pstrmatch(part, str)
    return string.match(part.Name, str)
end

local function getHitRegisteringPartsPositions(player)
    local ne = {}
    for i, v in pairs(player.Character:GetDescendants()) do
        if not v:IsA("BasePart") and not v:IsA("MeshPart") then continue end
        if pstrmatch(v, "Torso") or pstrmatch(v, "Head") or pstrmatch(v, "Arm") or pstrmatch(v, "Leg") or pstrmatch(v, "Foot") or pstrmatch(v, "Hand") then
            table.insert(ne, {[v.Name] = v.CFrame.Position})
        end
    end
    return ne
end

local function storeLocation(player)
    if not store[buffer] then
        store[buffer] = {tick(), loc = {}}
    end
    table.insert(store[buffer].loc, {player, getHitRegisteringPartsPositions(player)})
end

local function update()
    local t = tick()
    if t < n then return end
    n = tick() + tickRate

    if buffer >= maxBuffer then
        store[1] = nil
        table.remove(store, 1)
        buffer -= 1
    end

    for i, v in pairs(Players:GetPlayers()) do
        if not v.Character then continue end
        storeLocation(v)
    end
    buffer += 1
end

if LagCompensationEnabled then
    RunService.Heartbeat:Connect(update)
end