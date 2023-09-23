-- this initializes the casters within the ability modules
for i, v in pairs(game:GetService("ReplicatedStorage"):WaitForChild("ability"):WaitForChild("class"):GetChildren()) do
    require(v)
end