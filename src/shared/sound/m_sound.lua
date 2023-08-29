local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local replicateRemote = game:GetService("ReplicatedStorage"):WaitForChild("sound"):WaitForChild("remote"):WaitForChild("replicate")

local sound = {}
sound.__index = sound

function sound.PlayReplicated(snd)
    if RunService:IsClient() then
        snd:Play() -- play sound for player
        replicateRemote:FireServer("Play", snd) -- replicate to others
    else
        replicateRemote:FireAllClients("Play", snd)
    end
end

function sound.StopReplicated(snd)
    if RunService:IsClient() then
        snd:Stop()
        replicateRemote:FireServer("Stop", snd)
    else
        replicateRemote:FireAllClients("Stop", snd)
    end
end

function sound.PlayReplicatedClone(snd, whereFrom)
    if RunService:IsClient() then
        sound.PlayClone(snd, whereFrom)
        replicateRemote:FireServer("Clone", snd, whereFrom)
    else
        replicateRemote:FireAllClients("Clone", snd, whereFrom)
    end
end

function sound.PlayClone(snd, whereFrom, properties)
    local c = snd:Clone()
    c.Parent = whereFrom
    if properties then for i, v in pairs(properties) do c[i] = v end end
    c:Play()
    Debris:AddItem(c, c.TimeLength + 0.05)
    return c
end

function sound.server_FinishReplicated()
    
end

return sound