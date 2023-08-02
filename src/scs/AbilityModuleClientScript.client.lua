local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = ReplicatedStorage.Remotes.Ability.Get
local camera = workspace.CurrentCamera
local player = game:GetService("Players").LocalPlayer

local function canSee(part)
    local pos = part.Position
    local vector, inViewport = camera:WorldToViewportPoint(pos)
    local onScreen = inViewport and vector.Z > 0
    if onScreen then
        return true
    end
    return false
end

GetRemote.OnClientInvoke = function(action, ...)
    if action == "CanSee" then
        return canSee(...)
    end
end