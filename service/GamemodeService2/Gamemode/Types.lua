type GFunction = (GamemodeClass) -> ()
type GPlayerFunction = (GamemodeClass, Player) -> ()
type Dictionary<T> = { [string]: T }

export type RoundEndResult = "Timer" | "Condition"

export type PlayerData = {
    score:  number,
    kills:  number,
    deaths: number,
    money:  number,
    inventory: {
        weapon: {primary: string?, secondary: string},
        ability: {primary: string?, secondary: string?}
    }
}
export type PlayerDataClass = {
    AddPlayer:      (PlayerDataClass, player: Player) -> (),
    RemovePlayer:   (PlayerDataClass, player: Player) -> (),
    GetPlayer:      (PlayerDataClass, player: Player) -> (),
    GetPlayers:     (PlayerDataClass) -> (Dictionary<Player>),
    Get:            (PlayerDataClass, player: Player, key: string) -> (any),
    Set:            (PlayerDataClass, player: Player, key: string, value: any) -> (),
    Increment:      (PlayerDataClass, player: Player, key: string, amnt: number) -> (),
    Decrement:      (PlayerDataClass, player: Player, key: string, amnt: number) -> (),
}

export type GamemodeModule = {
    CurrentGamemode:        GamemodeClass | false,
    ModuleConnections:      {},
    GamemodeConnections:    {},
    
    Start:  (GamemodeModule) -> (),
    Stop:   (GamemodeModule) -> (),
    RoundStart: (GamemodeModule) -> (),
}

export type GamemodeClass = {
    TimeElapsed: number,
    CurrentRound: number,

    Spawns: Folder,

    Options: GamemodeOptions,
    Connections: {},

    PlayerData: PlayerDataClass,

    SpawnPlayer: GPlayerFunction,

    PlayerJoinedWhileWaiting: GPlayerFunction,
    PlayerJoinedDuringGame: GPlayerFunction,
    PlayerLeftWhileWaiting: GPlayerFunction,
    PlayerLeftDuringGame: GPlayerFunction,

    PlayerDied: (GamemodeClass, died: Player, killer: Player) -> (),
    PlayerKilledSelf: GPlayerFunction,

    Start: GFunction,
    End: GFunction,
    Stop: GFunction,

    RoundStart: GFunction,
    RoundEnd: (GamemodeClass, result: RoundEndResult) -> ()
}

export type GamemodeOptions = {
    MAIN_MENU_TYPE:     string,

    MIN_PLAYERS:        number,
    MAX_PLAYERS:        number,
    START_HEALTH:       number,
    START_SHIELD:       number,
    START_HELMET:       boolean,
    START_INVENTORY:    {
                          weapon: {primary: string?, secondary: string},
                          ability: {primary: string?, secondary: string?}
                        },

    MAX_ROUNDS:         number,
    ROUND_LENGTH:       number,

    BUY_MENU_ENABLED:   boolean,
}

return nil