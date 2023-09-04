local Deathmatch = {
    Name = "Deathmatch",

    config = {
        updateInterval = 5,
    }
}

local gamemodecfg = require(game:GetService("ServerScriptService"):WaitForChild("gamemode"):WaitForChild("class"):WaitForChild("Deathmatch"))
Deathmatch.config.minParty = gamemodecfg.minimumPlayers
Deathmatch.config.maxParty = gamemodecfg.maximumPlayers

return Deathmatch