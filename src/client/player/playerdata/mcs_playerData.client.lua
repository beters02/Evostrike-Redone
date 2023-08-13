local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local clientPlayerDataModule = require(Framework.shm_clientPlayerData.Location).initialize()