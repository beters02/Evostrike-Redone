local inputs = {LeftShift = false, P = false}
local debounce = false

game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if inputs[input.KeyCode.Name] ~= nil then
        inputs[input.KeyCode.Name] = true
    end
end)

game.UserInputService.InputEnded:Connect(function(input, gp)
    if inputs[input.KeyCode.Name] ~= nil then
        inputs[input.KeyCode.Name] = false
        debounce = false
    end
end)

game:GetService("RunService").RenderStepped:Connect(function(dt)
    if inputs.LeftShift and inputs.P and not debounce then
        debounce = true
        for i, v in pairs(workspace.CurrentCamera:WaitForChild("viewModel"):GetDescendants()) do
            if v:IsA("Part") or v:IsA("MeshPart") then
                v.Transparency = 1
            end
        end
        game:GetService("Players").LocalPlayer.PlayerGui.HUD.Crosshair.Enabled = false
    end
end)