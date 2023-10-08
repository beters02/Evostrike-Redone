local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local replicateRemote = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Sound"):WaitForChild("remote"):WaitForChild("replicate")

local sound = {}
sound.__index = sound

function sound.PlayReplicated(snd, volume)
    if RunService:IsClient() then
        snd:Play() -- play sound for player
        replicateRemote:FireServer("Play", snd, volume) -- replicate to others
    else
        replicateRemote:FireAllClients("Play", snd, volume)
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

function sound.PlayReplicatedClone(snd, whereFrom, playLocalOnClient)
    if RunService:IsClient() then
        sound.PlayClone(snd, playLocalOnClient and whereFrom.Parent.Parent or whereFrom)
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

--@summary Play all sounds in a table
function sound.Sounds(action, sounds, ...)
    for i, v in pairs(sounds) do
        print(v)
        sound[action](v, ...)
    end
end

function sound.server_FinishReplicated()
    
end

return sound