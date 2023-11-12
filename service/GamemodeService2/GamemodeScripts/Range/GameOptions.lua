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
    buy_menu_add_instant: boolean,
    end_screen_length: number,
    base_sc_earned: number,
    base_xp_earned: number,
    spawn_invincibility: number | false,
    starting_shield: number | false,
    starting_helmet: boolean,
    starting_health: number,
}

local GameOptions = {}

function GameOptions.new(overrideOptions: table?)
    local self: GameOptions = {
        min_players = 4,
        max_players = 4,
        round_length = 2 * 60,
        score_to_win_round = 1,
        score_to_win_game = 13,
        can_damage = true,
        restart_on_end = false,
        respawn_enabled = false,
        respawn_length = 3,
        buy_menu_enabled = false,
        buy_menu_add_instant = false,
        end_screen_length = 15,
        base_sc_earned = 35,
        base_xp_earned = 200,
        spawn_invincibility = 0,
        starting_shield = 50,
        starting_helmet = true,
        starting_health = 100,
        barriers_length = 15,
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