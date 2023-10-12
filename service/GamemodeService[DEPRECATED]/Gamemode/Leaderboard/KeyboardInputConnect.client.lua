local gui = script.Parent
local player = game:GetService("Players").LocalPlayer

-- connect open
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
	if player:GetAttribute("Typing") then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		gui.Enabled = true
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.Tab then
        gui.Enabled = false
    end
end)