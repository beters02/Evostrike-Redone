local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local killer = script:WaitForChild("killerObject").Value
local player = game:GetService("Players").LocalPlayer

camera.CameraType = Enum.CameraType.Scriptable

local conn = RunService.RenderStepped:Connect(function(dt)
	camera.CFrame = camera.CFrame:Lerp(CFrame.new(killer.Character.PrimaryPart.CFrame.Position + Vector3.new(5, 10, 0) - camera.CFrame.LookVector, killer.Character.PrimaryPart.CFrame.Position), 10 * dt)
end)

script:WaitForChild("Destroy").OnClientEvent:Once(function()
	conn:Disconnect()
	camera.CameraType = Enum.CameraType.Custom
end)