local SelectionService = game:GetService("Selection")

local tb = plugin:CreateToolbar("MaterialConvert")
local sa_to_mat_butt = tb:CreateButton("To Material", "Convert a SurfaceAppearance to a MaterialVariant", "rbxassetid://11558113671")
local mat_to_sa_butt = tb:CreateButton("To SurfaceAppearance", "Convert a MaterialVariant to a SurfaceAppearance", "rbxassetid://11558113671")

local function SaToMat()
    local selected = SelectionService:Get()
    if #selected == 0 then return end

    for _, obj: SurfaceAppearance? in pairs(selected) do
        if not obj:IsA("SurfaceAppearance") then
            warn("Cannot convert object of type " .. typeof(obj) .. " to MaterialVariant.")
            continue
        end

        local inst = Instance.new("MaterialVariant", obj.Parent)
        inst.Name = obj.Name
        inst.RoughnessMap = obj.RoughnessMap
        inst.ColorMap = obj.ColorMap
        inst.MetalnessMap = obj.MetalnessMap
        inst.NormalMap = obj.NormalMap
        obj:Destroy()
    end
end

local function MatToSa()
    local selected = SelectionService:Get()
    if #selected == 0 then return end

    for _, obj: MaterialVariant? in pairs(selected) do
        if not obj:IsA("MaterialVariant") then
            warn("Cannot convert object of type " .. typeof(obj) .. " to SurfaceAppearance.")
            continue
        end

        local inst = Instance.new("SurfaceAppearance", obj.Parent)
        inst.Name = obj.Name
        inst.RoughnessMap = obj.RoughnessMap
        inst.ColorMap = obj.ColorMap
        inst.MetalnessMap = obj.MetalnessMap
        inst.NormalMap = obj.NormalMap
        obj:Destroy()
    end
end

sa_to_mat_butt.Click:Connect(SaToMat)
mat_to_sa_butt.Click:Connect(MatToSa)