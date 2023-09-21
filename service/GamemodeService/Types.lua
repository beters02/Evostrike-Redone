export type Gamemode = {
    Name: string,
    Status: boolean,
    GameVariables: table,
    GameData: table,
    PlayerData: table,

    Start: (table, ...any) -> (...any),
    Stop: (table, ...any) -> (...any),
    Pause: (table, ...any) -> (...any),
}

export type RoundEndCondition = "teamEliminated" | "playerEliminated" | "timerOnly" | "scoreReached"

export type RoundTimerFinishedResult = "RoundOverWon" | "RoundOverTimer" | "Restart"

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

return nil