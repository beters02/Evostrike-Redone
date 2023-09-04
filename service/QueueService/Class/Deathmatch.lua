-- [[ Deathmatch Queue Class ]]

local Deathmatch = {
    Name = "Deathmatch",
    QueueInterval = 5,
    MinParty = 1,
    MaxParty = 8
}

-- Get config from Gamemode
--[[local gamemodecfg = require(game:GetService("ServerScriptService"):WaitForChild("gamemode"):WaitForChild("class"):WaitForChild("Deathmatch"))

Deathmatch.MaxParty = gamemodecfg.maximumPlayers
Deathmatch.MinParty = gamemodecfg.minimumPlayers]]
return Deathmatch