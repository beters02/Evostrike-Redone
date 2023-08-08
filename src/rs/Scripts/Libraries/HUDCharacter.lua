local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUDCharacter = {
    _stored = nil,
}
HUDCharacter.__index = HUDCharacter

function HUDCharacter.new(char, viewportFrame)
    local self = {}
    self.player = Players:GetPlayerFromCharacter(char)
    self.model = _initModel(char, viewportFrame)
    self.humanoid = self.model:WaitForChild("Humanoid")
    self.animator = self.humanoid:WaitForChild("Animator")
    HUDCharacter._stored = Instance.new("BindableEvent")
    HUDCharacter._stored.Parent = ReplicatedStorage.Temp

    self.Remove = function()
        self.model:Destroy()
        HUDCharacter._stored = nil
        self = nil
    end

    self.LoadAnimation = function(animation)
        local waitForAnimationProvider = viewportFrame:WaitForChild("WorldModel"):WaitForChild("CharacterModel")
        return self.animator:LoadAnimation(animation)
    end

    HUDCharacter._stored:Fire(self)
    task.wait()
    HUDCharacter._stored = self
    return self
end

function HUDCharacter.GetHUDCharacter()
    local stored = HUDCharacter._stored
    if not stored then
        local c = 0
        repeat
            c += 1
            task.wait(1)
            stored = HUDCharacter._stored
        until stored or c == 3
    end

    if typeof(stored) == "RBXScriptSignal" then
        stored.Event:Wait()
    end

    return HUDCharacter._stored
end



function _initModel(char, viewportFrame)
    char.Archivable = true
    local model = char:Clone()
    char.Archivable = false
    model.Name = "CharacterModel"
    model:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0,1.5,1)) * CFrame.Angles(0, 45, 0))

    for i, v in pairs(model:GetDescendants()) do -- disable clone scripts
        if v:IsA("Script") or v:IsA("LocalScript") then
            v:Destroy()
        elseif v:IsA("Part") or v:IsA("MeshPart") and v.Name ~= "HumanoidRootPart" then
            v.Transparency = 0
        end
    end

    model.Parent = viewportFrame:WaitForChild("WorldModel")
    return model
end

Players.LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        HUDCharacter._stored.Remove()
    end)
end)

return HUDCharacter