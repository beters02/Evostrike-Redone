-- default died event connection
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DiedEvent = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")

DiedEvent.OnServerEvent:Connect(function(killed, killer)
    for i, v in pairs(Players:GetPlayers()) do
        if v ~= killed then
            DiedEvent:FireClient(v, killed, killer)
        end
    end
end)