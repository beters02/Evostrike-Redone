local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local clientPlayerDataModule = require(Framework.shm_clientPlayerData.Location).initialize()
local nxt = tick()

local update = RunService.RenderStepped:Connect(function()
    if tick() < nxt then return end
    nxt = tick() + 10
    
    clientPlayerDataModule:Save()
    print('Auto saved settings!')
end)

game:GetService("Players").PlayerRemoving:Connect(function(plr)
    if player == plr then
        update:Disconnect()
        clientPlayerDataModule:Save()
    end
end)