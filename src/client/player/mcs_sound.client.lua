local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local Debris = game:GetService("Debris")
local replicateRemote = game:GetService("ReplicatedStorage"):WaitForChild("sound"):WaitForChild("remote"):WaitForChild("replicate")

replicateRemote.OnClientEvent:Connect(function(action, sound, whereFrom)
    if not sound then return end
    if action == "Play" then
        sound:Play()
    elseif action == "Clone" then
        local c = sound:Clone()
        c.Parent = whereFrom
        c:Play()
        Debris:AddItem(c, c.TimeLength + 0.05)
    elseif action == "Stop" then
        sound:Stop()
    end
end)