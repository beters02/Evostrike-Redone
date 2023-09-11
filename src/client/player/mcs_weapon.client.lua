local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local PlayerDiedBindable = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathBE")

-- wait for character to load initially
local _ = player.Character or player.CharacterAdded:Wait()

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.shm_clientPlayerData.Location)
local UserInputService = game:GetService("UserInputService")
local WeaponRemotes = game.ReplicatedStorage:WaitForChild("weapon"):WaitForChild("remote")
local WeaponAddRemoveEvent = WeaponRemotes:WaitForChild("addremove")
local WeaponReplicateEvent = WeaponRemotes:WaitForChild("replicate")
local SharedWeaponFunc = require(Framework.shfc_sharedWeaponFunctions.Location)
local vm = workspace.CurrentCamera:WaitForChild("viewModel")

-- Init Weapon Inventory Controller

local controller = {primary = false, secondary = false, ternary = false, inputs = false, currentEquipped = false} -- primary = {weaponName, tool}

function equip(slot, ignoreHumEquip)
	print('equip')
	if not controller[slot] then return end
	if controller.currentEquipped == slot then
		return
	end
	if ignoreHumEquip then return end
	
	local succ, err = pcall(function()
		print(controller[slot][2].Parent)
		task.delay(0.5, function()
			print(controller[slot][2].Parent)
		end)
		player.Character.Humanoid:EquipTool(controller[slot][2])
	end)

	if succ then
		controller.currentEquipped = slot
	else warn(err) end
	
end

-- Connect Weapon Events

local RemoveQueued = false

-- Add/Remove
WeaponAddRemoveEvent.OnClientEvent:Connect(function(action, ...)
	if action == "Remove" then
		RemoveQueued = true
		local tool = ...

		-- if equipped
		if tool and tool.Parent == player.Character then

			-- destroy viewmodel model
			if vm and vm:FindFirstChild("Equipped") and #vm.Equipped:GetChildren() > 0 then
				vm.Equipped:GetChildren()[1]:Destroy()
				for i, v in pairs(vm.AnimationController:GetPlayingAnimationTracks()) do
					v:Stop()
				end
			end
			
		end

		for i, v in pairs(controller) do
			if type(v) ~= "table" then continue end
			if string.match(string.lower(v[1]), string.lower(tool.Name)) then
				controller[i] = nil
				break
			end
		end

		RemoveQueued = false
	elseif action == "Add" then
		if RemoveQueued then repeat task.wait() until not RemoveQueued end
		local weaponName, weaponOptions, _, tool, forceEquip = ...
		controller[weaponOptions.inventorySlot] = {weaponName, tool}
		if forceEquip then
			equip(weaponOptions.inventorySlot, true)
		end
	end
end)

-- Replicate
WeaponReplicateEvent.OnClientEvent:Connect(function(functionName, ...)
	return SharedWeaponFunc[functionName](...)
end)

-- Init Equip Inputs

local equipDebounce = tick()
local processDebounce = false

local keys = {}
keys.primary = {path = "options.keybinds.primaryWeapon"}
keys.secondary = {path = "options.keybinds.secondaryWeapon"}
keys.ternary = {path = "options.keybinds.ternaryWeapon"}

-- Connect playerdata for each key
for i, v in pairs(keys) do
	keys[i].key = PlayerData:Get(v.path)
	PlayerData:Changed(v.path, function(newValue)
		keys[i].key = newValue
	end)
end

-- Connect Equip Inputs
UserInputService.InputBegan:Connect(function(input, gp)
	if gp or player:GetAttribute("Typing") or player.PlayerGui.MainMenu.Enabled then return end
	if not player.Character or not player.Character.Humanoid or player.Character.Humanoid.Health <= 0 then return end
	if tick() < equipDebounce or processDebounce then return end

	processDebounce = true

	-- check if we're equipping on any key
	for i, v in pairs(keys) do
		if input.KeyCode.Name == v.key then
			equipDebounce = tick() + 0.1
			equip(i)
		end
	end

	processDebounce = false

end)

PlayerDiedBindable.Event:Connect(function()
	for i, v in pairs(controller) do
		if i == "inputs" then continue end
		controller[i] = false
	end
end)