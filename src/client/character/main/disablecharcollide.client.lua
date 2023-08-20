local char = script.Parent.Parent

task.wait(1)

for i, v in pairs(char:GetDescendants()) do
    if v:IsA("Part") or v:IsA("BasePart") then
        v.CanCollide = false
    end
end