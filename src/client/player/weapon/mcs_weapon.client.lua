local WeaponRemotes = game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("remote")
local WeaponAddRemoveEvent = WeaponRemotes:WaitForChild("addremove")

local player = game:GetService("Players").LocalPlayer
local vm = workspace.CurrentCamera:WaitForChild("viewModel")

-- Connect Weapon Events

-- Add/Remove
WeaponAddRemoveEvent.OnClientEvent:Connect(function(action, tool)
    if action ~= "Remove" then return end
	-- if equipped
	if tool.Parent == player.Character then

		-- destroy viewmodel model
		if not vm or not vm:FindFirstChild("Equipped") then return end
		vm.Equipped:GetChildren()[1]:Destroy()
		for i, v in pairs(vm.AnimationController:GetPlayingAnimationTracks()) do
			v:Stop()
		end
	end
end)