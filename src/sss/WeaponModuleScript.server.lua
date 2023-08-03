local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local WeaponModuleLoc = game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("Weapon")
local WeaponModule = require(WeaponModuleLoc)
local WeaponRemotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Weapon")
local WeaponAddRemoveEvent = WeaponRemotes:WaitForChild("AddRemove")
local WeaponGetEvent = WeaponRemotes:WaitForChild("Get")
local WeaponReplicateEvent = WeaponRemotes.Replicate
local WeaponGetServerFunc = WeaponRemotes:WaitForChild("ServerGet")

-- Add weapon controller and weapon motor on CharacterAdded
Players.PlayerAdded:Connect(function(player)
	print(player)
	player.CharacterAdded:Connect(function(char)
		WeaponModule.AddWeaponController(char)
	end)
end)

-- Add weapon controller to anyone already in the game
local currplayers = Players:GetPlayers()
if #currplayers > 0 then
	for i, v in pairs(currplayers) do
		print(v)
		if v.Character then
			WeaponModule.AddWeaponController(v.Character)
		end
		v.CharacterAdded:Connect(function(char)
			WeaponModule.AddWeaponController(char)
		end)
	end
end

local store
local buffer

-- Connect Weapon Events
WeaponAddRemoveEvent.OnServerEvent:Connect(function(player, action, ...)
	if action == "Add" then
		WeaponModule.Add(player, ...)
	elseif action == "Remove" then
		WeaponModule.Remove(player, ...)
    end
end)

WeaponGetEvent.OnServerInvoke = function(player, action, ...)
	if action == "Options" then
		local weaponOptions = WeaponModuleLoc.Options:FindFirstChild(...)
		if not weaponOptions then
			return false
		end
		
		return require(weaponOptions)
	elseif action == "CameraRate" then
		return require(WeaponModuleLoc.Options.Camera).updateRate
	elseif action == "FireCameraDownWait" then
		return require(WeaponModuleLoc.Options.Camera).fireDownWaitLength
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