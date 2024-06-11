local Extras = game.ReplicatedStorage.Remotes.Extras
local Admin = require(game.ServerStorage.Stored.AdminIDs)
local AimlockScript = script:WaitForChild("AimlockScript")

local actions = {
    aimlock = function(plr)
        
    end
}

Extras.OnServerInvoke = function(plr, action)
    if not Admin:IsAdmin(plr) then
        return false, "Must be admin to perform this command."
    end

    if not plr.Character then
        return false, "Must be alive to use aimlock"
    end

    if plr.Character:FindFirstChild("AimlockScript") then
        plr.Character.AimlockScript:Destroy()
        return true, "Aimlock disabled."
    end

    AimlockScript:Clone().Parent = plr.Character
    return true, "Aimlock enabled."
end