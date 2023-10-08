local SelectionService = game:GetService("Selection")
local Toolbar = plugin:CreateToolbar("SetCameraModel")
local Button = Toolbar:CreateButton("Set", "Set Camera to Model Icon Position", "rbxassetid://11558113671")

local Offset = Vector3.new(1.5, 0, 2)

local function GetCamera()
    local _camera = workspace:FindFirstChild("Camera")
    if not _camera then
        return warn("No camera found")
    end
    return _camera
end

local function SetCamera()
    local camera = GetCamera()
    if not camera then return end

    local selected = SelectionService:Get()[1]
    if not selected then return end

    local cframe

    if selected:IsA("MeshPart") or selected:IsA("BasePart") then
        cframe = selected.CFrame
    elseif selected:IsA("Attachment") then
        cframe = CFrame.new(selected.WorldPosition + Offset)
    elseif selected:IsA("Model") then
        local _gc = selected:FindFirstChild("GunComponents")
        if not _gc then return end
        cframe = CFrame.new(_gc.WeaponHandle.FirePoint.WorldPosition + Offset)
    else
        return warn("Please select a valid Part (BasePart, MeshPart, Attachment, Weapon Model) to lock your camera")
    end

    camera.CameraType = "Scriptable"
    camera.CFrame = cframe
    task.wait()
    camera.CameraType = "Fixed"
    print("Moved camera to: " .. selected.Name)
end

Button.Click:Connect(function() SetCamera() end)