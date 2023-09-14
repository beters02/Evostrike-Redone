for i, v in pairs(game:GetService("ReplicatedStorage"):WaitForChild("Services"):GetChildren()) do
    require(v)
end