local replicateRemote = game:GetService("ReplicatedStorage"):WaitForChild("sound"):WaitForChild("remote"):WaitForChild("replicate")

replicateRemote.OnServerEvent:Connect(function(player, action, sound, whereFrom)
    for i, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v == player then continue end
        replicateRemote:FireClient(v, action, sound, whereFrom)
    end
end)