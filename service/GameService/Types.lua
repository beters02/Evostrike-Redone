export type GameServiceStatus = "ENDED" | "STARTED" | "LOADING"

-- All games include a Timer that will end the round.
-- Custom:     Round end is decided within the Gamemode Class
export type RoundEndCondition = "PlayerKilled" | "TeamKilled" | "Timer" | "Custom"

-- TimerScore: Game ends when the timer ends and whoever has the highest score wins. (1 round)
-- Score:      Game ends when a Player reaches a certain score. (1 round)
-- RoundScore: Game ends when a certain amound of rounds won has been reached. (set amount of rounds)
-- Custom:     Game end is decided within the Gamemode Class
export type GameEndCondition = "Score" | "RoundScore" | "TimerScore" | "Custom"

-- If RoundEndCondition is Timer, it will fire "Timer" anyways.
export type RoundEndResult = "Condition" | "Timer"

type PlayerInventory = {primary: string?, secondary: string?}

export type GamemodeOptions = {
    MIN_PLAYERS: number,
    MAX_PLAYERS: number,

    TEAMS_ENABLED: boolean,
    TEAM_SIZE: number,
    
    MAX_ROUNDS: number,
    ROUND_LENGTH: number,
    OVERTIME_ENABLED: boolean,
    OVERTIME_SCORE_TO_WIN: number,
    SCORE_TO_WIN: number,

    SPECTATE_ENABLED: boolean,
    PLAYER_SPAWN_ON_JOIN: boolean,
    REQUIRE_REQUEST_SPAWN: boolean,
    RESPAWN_ENABLED: boolean,
    RESPAWN_LENGTH: number,

    ROUND_END_CONDITION: RoundEndCondition,
    GAME_END_CONDITION: GameEndCondition,

    START_HEALTH: number,
    START_SHIELD: number,
    START_HELMET: boolean,
    SPAWN_INVINCIBILITY: number,
    
    MENU_TYPE: string,
    BUY_MENU_ENABLED: boolean,
    BUY_MENU_ADD_INSTANT: boolean,

    START_INVENTORY: {ABILITIES: PlayerInventory, WEAPONS: PlayerInventory},
    START_CAMERA_CFRAME_MAP: {}
}

return nil