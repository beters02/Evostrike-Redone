local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = ReplicatedStorage.Remotes.Ability.Get
local camera = workspace.CurrentCamera

local function canSee(part)
    local vector, inViewport = camera:WorldToViewportPoint(part.Position)
    local onScreen = inViewport and vector.Z > 0
    return onScreen
end

GetRemote.OnClientInvoke = function(action, ...)
    local player = game:GetService("Players")
    if action == "CanSee" then
        return canSee(...)
    end
end