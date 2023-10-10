-- Purpose: Because of the way I have chosen to do Grenade Repication via Client FastCast and RemoteEvents,
-- I figured it would be easier to create a Service which stores grenade data in an optimized and organized way
-- Initialized on Require, must be reqiured from Client and Server

local GrenadeService = {}
local RemoteEvent = script:WaitForChild("Events").RemoteEvent

function GrenadeService:Add(player, ability: string) -- Adds a Grenade into the environment.
    RemoteEvent:FireClient(player, "AddLocal", ability)
    RemoteEvent:FireAllClients("AddGlobal", ability, player)
end

function GrenadeService:Remove(player, ability)
    RemoteEvent:FireClient(player, "RemoveLocal", ability)
    RemoteEvent:FireAllClients("RemoveGlobal", ability, player)
end

return GrenadeService