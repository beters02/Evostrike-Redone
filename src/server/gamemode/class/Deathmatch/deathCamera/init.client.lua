local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local killer = script:WaitForChild("killerObject").Value

RunService.RenderStepped:Connect(function(dt)
    camera.CFrame = camera.CFrame:Lerp(killer.Character.PrimaryPart.CFrame + CFrame.new(Vector3.new(0, 2, 0)), dt * 40)
end)