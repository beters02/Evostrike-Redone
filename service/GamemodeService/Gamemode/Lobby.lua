local EvoPlayer = require(game.ReplicatedStorage.Modules.EvoPlayer)
local Lobby = {}
Lobby.GameVariables = {
    minimum_players = 1,
    maximum_players = 12,
    teams_enabled = false,
    players_per_team = 1,

    characterAutoLoads = false,
    respawns_enabled = true,
    respawn_length = 1,

    rounds_enabled = false,

    queueFrom_enabled = true, -- Can a player queue while in this gamemode?
    queueTo_enabled = false,    -- Can a player queue into this gamemode while in a queueFrom enabled gamemode?

    kick_players_on_end = false,

    can_players_damage = false,
    starting_health = 100,
    starting_shield = 50,
    starting_helmet = true,

    starting_abilities = {
        "Dash"
    }
}

--@summary Called when a Player Joins during a round.
-- if rounds_enabled = false, this is for when a player joins after the game has started.
function Lobby:PlayerJoinedDuringRound(player)
    self:PlayerInit(player, true)
    EvoPlayer:DoWhenLoaded(player, function()
        self:PlayerSpawn(player)
    end)
end

return Lobby