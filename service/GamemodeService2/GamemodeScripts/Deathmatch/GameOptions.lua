export type Inventory = {
    Weapons: {primary: InventorySlot, secondary: InventorySlot, ternary: InventorySlot},
    Abilities: {primary: InventorySlot, secondary: InventorySlot}
}
export type InventorySlot = string | false

export type GameOptions = {
    game_type: "Round" | "Score" | "Custom",
    min_players: number,
    max_players: number,
    round_length: number,
    round_end_condition: "KillScoreReached" | "PlayerDied" | "TeamDied",
    score_to_win_round: number,
    score_to_win_game: number,
    can_damage: boolean,
    restart_on_end: boolean,
    respawn_enabled: boolean,
    respawn_length: number,
    inventory: Inventory,
    buy_menu_enabled: boolean,
    buy_menu_add_instant: boolean
}

local GameOptions = {}

function GameOptions.new(overrideOptions: table?)
    local self: GameOptions = {
        min_players = 1,
        max_players = 8,
        round_length = 60,
        score_to_win_round = 1,
        score_to_win_game = 8,
        can_damage = true,
        restart_on_end = true,
        respawn_enabled = false,
        respawn_length = 3,
        buy_menu_enabled = true,
        buy_menu_add_instant = false,
        inventory = {
            Weapons = {
                primary = "ak103",
                secondary = "glock17",
                ternary = "knife"
            },
            Abilities = {
                primary = "Dash",
                secondary = "LongFlash"
            }
        }
    }
    if overrideOptions then
        for i, v in pairs(overrideOptions) do
            self[i] = v
        end
    end
    return self
end

return GameOptions