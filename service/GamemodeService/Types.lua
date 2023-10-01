export type Gamemode = {
    Name: string,
    Status: boolean,
    GameVariables: table,
    GameData: table,
    PlayerData: table,

    Start: (Gamemode, ...any) -> (...any),
    Stop: (Gamemode, ...any) -> (...any),
    Pause: (Gamemode, ...any) -> (...any),

    PlayerSpawn: (Gamemode, Player) -> (),
    PlayerSpawnAll: (Gamemode) -> ()
}

export type RoundEndCondition = "TeamEliminated" | "PlayerEliminated" | "TimerOnly" | "ScoreReached"
export type RoundTimerFinishedResult = "RoundOverWon" | "RoundOverTimer" | "Restart"
export type RoundOverTimerCallbackType = "RoundScore" | "Health" | "Random" | false
export type RoundScoreIncrementCondition = "Kills" | "Custom"

export type RoundTimer = {
    Time: number,
    TimeLength: number,
    TimeLeft: () -> (number),
    Status: "Init" | "Started" | "Stopped" | "Paused",
    Finished: BindableEvent,
    TimeUpdated: BindableEvent,

    Start: () -> (boolean?),
    Stop: () -> (boolean?),
    Pause: () -> (boolean?)
}

-- [GameType: Round]    Ends by specified game_rounds_to_win
-- [GameType: Timer]    Ends by timer
-- [GameType: Score]    Ends when a Player reaches the specified game_score_to_win, Score is incremented by kills.
-- [GameType: Custom]   Ends by manual conditioning
export type GameType = "Round" | "Score" | "Timer" | "Custom"

return nil