export type Strafe = number
export type ValidGamemodes = "1v1" | "2v2" | "5v5"

export type Conditions = {
    Won: boolean,

    RoundsWon: number,
    RoundsLost: number,
    TotalRoundsInGamemode: number,
    TotalRoundsNeedToWinInGamemode: number,

    Kills: number,
    Deaths: number,

    ShotsTaken: number,
    ShotsHit: number,
    Headshots: number,

    FlashUsed: number,
    PlayersFlashed: number,

    MollyUsed: number,
    TotalMollyDamage: number,

    HEUsed: number,
    TotalHEDamage: number,

    SmokeUsed: number,
    SmokeKills: number
}

return nil