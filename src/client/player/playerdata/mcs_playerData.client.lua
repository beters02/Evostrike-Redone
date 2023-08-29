local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local clientPlayerDataModule = require(Framework.shm_clientPlayerData.Location).initialize()
local nxt = tick()

RunService.RenderStepped:Connect(function()
    if tick() < nxt then return end
    nxt = tick() + 5

    clientPlayerDataModule.UpdateToStoredFromCache()
end)