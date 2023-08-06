local Functions = {}

function Functions:GetModule(moduleName: string): table
    local lookLocation = self.FolderLocation:FindFirstChild("Scripts") or self.FolderLocation
    for i, v in pairs(lookLocation:GetDescendants()) do
        if not v:IsA("ModuleScript") then continue end
        if v.Name == moduleName then return require(v) end
    end
    warn("Could not find module: moduleName!")
    return false
end

return Functions