local Lobby = {}
Lobby.GameVariables = {
    game_type = "Custom",
    minimum_players = 1,
    maximum_players = 12,
    teams_enabled = false,
    players_per_team = 1,

    buy_menu_enabled = true,
    buy_menu_add_bought_instant = true,
    buy_menu_starting_loadout = {
        Weapons = {primary = false, secondary = false},
        Abilities = {primary = false, secondary = false}
    },

    bots_enabled = true,

    characterAutoLoads = false,
    respawns_enabled = true,
    respawn_length = 1,

    leaderboard_enabled = true,

    rounds_enabled = false,

    queueFrom_enabled = true, -- Can a player queue while in this gamemode?
    queueTo_enabled = false,    -- Can a player queue into this gamemode while in a queueFrom enabled gamemode?

    kick_players_on_end = false,

    can_players_damage = true,
    starting_health = 100,
    starting_shield = 50,
    starting_helmet = true,
}

--@summary Called when a Player Joins during a round.
-- if rounds_enabled = false, this is for when a player joins after the game has started.
function Lobby:PlayerJoinedDuringRound(player)
    self:PlayerInit(player, true)
    self:PlayerSpawn(player)
end

return Lobby