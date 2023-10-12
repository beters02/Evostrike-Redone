local killer = script:WaitForChild("killerObject").Value
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

if not killer then killer = player end
local lastGoodCF = CFrame.new()
local primcf = CFrame.new()
local success = false

--camera.CameraType = Enum.CameraType.Scriptable

local conn
conn = game:GetService("RunService").RenderStepped:Connect(function(dt)
	success, primcf = pcall(function()
		return killer.Character.PrimaryPart.CFrame
	end)
	if not success or not killer.Character or not camera then
		lastGoodCF = lastGoodCF
	else
		lastGoodCF = camera.CFrame:Lerp(CFrame.new(primcf.Position + Vector3.new(5, 10, 0) - camera.CFrame.LookVector, primcf.Position), 10 * dt)
	end
	camera.CFrame = lastGoodCF
end)

script:WaitForChild("Finished").OnClientEvent:Connect(function()
    conn:Disconnect()
	camera.CameraType = Enum.CameraType.Custom
end)