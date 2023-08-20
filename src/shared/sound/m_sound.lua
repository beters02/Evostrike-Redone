local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local replicateRemote = game:GetService("ReplicatedStorage"):WaitForChild("sound"):WaitForChild("remote"):WaitForChild("replicate")

local sound = {}
sound.__index = sound

function sound.PlayReplicated(snd)
    if RunService:IsClient() then
        -- play sound for player
        snd:Play()
        -- replicate to others
        replicateRemote:FireServer("Play", snd)
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
        local c = snd:Clone()
        c.Parent = whereFrom
        c:Play()
        Debris:AddItem(c, c.TimeLength + 0.05)
        replicateRemote:FireServer("Clone", snd)
    else
        replicateRemote:FireAllClients("Clone", snd)
    end
end

function sound.server_FinishReplicated()
    
end

return sound