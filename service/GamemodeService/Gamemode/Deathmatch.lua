--  In this Deathmatch gamemode, players will spawn at a random point in the points array.
--  Players need to reach a score of 100 to win the game. Respawns are enabled.
--  (Players will recieve 1 game point after getting 100 kills in the round, winning them the game.)

local Deathmatch = {}

Deathmatch.GameVariables = {
    minimum_players = 1,
    maximum_players = 8,
    teams_enabled = false,
    players_per_team = 1,
    
    buy_menu_enabled = true,

    characterAutoLoads = false,
    respawns_enabled = false,
    respawn_length = 3,

    rounds_enabled = true,
    round_length = 60,
    round_end_condition = "scoreReached",
    round_end_timer_assign = "roundScore",

    -- if scoreReached
    round_score_to_win_round = 100,
    round_score_increment_condition = "kills", -- other

    overtime_enabled = false,

    game_score_to_win_game = 1,
    game_end_condition = "scoreReached",

    queueFrom_enabled = false, -- Can a player queue while in this gamemode?
    queueTo_enabled = true,    -- Can a player queue into this gamemode while in a queueFrom enabled gamemode?

    kick_players_on_end = false,

    can_players_damage = true,
    starting_health = 100,
    starting_shield = 50,
    starting_helmet = true
}

local spawnPoints = {Vector3.new(5, 0, 5), Vector3.new(10, 0, 5), Vector3.new(5, 0, 10), Vector3.new(10, 0, 10)}
function Deathmatch:GetSpawnPoint()
    return spawnPoints[math.random(1,#spawnPoints)]
end

-- Override the default PlayerSpawn function
function Deathmatch:PlayerSpawn(player)
    player:LoadCharacter()
    player.Character:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(self:GetSpawnPoint())
end

-- Don't do anything special when a player kills themself
Deathmatch.PlayerDiedIsKiller = false

return Deathmatch