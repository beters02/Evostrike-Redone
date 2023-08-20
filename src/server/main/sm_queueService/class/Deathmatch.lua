local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local dm = {
    options = {partySize = 2, partySizeMax = 4, checkInterval = 5}
}

function dm:SendPartyToPlace(party: table)
    local _players = {}
    for i, v in pairs(party) do _players[i] = Players:GetPlayers()[v] end

    local mapID = self:RequestRandomMap()
    TeleportService:TeleportToPrivateServer(mapID, TeleportService:ReserveServer(mapID), _players, false, {RequestedGamemode = "Deathmatch"})
end

function dm:RequestRandomMap()
    return 14504041658
end

return dm