local Shared = require(game.ReplicatedStorage.Services.GamemodeService2.GamemodeScripts.Shared)

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
    inventory: Shared.Inventory,
    buy_menu_enabled: boolean,
    buy_menu_add_instant: boolean,
    end_screen_length: number,
    base_sc_earned: number,
    base_xp_earned: number,
    spawn_invincibility: number | false,
    starting_shield: number | false,
    starting_helmet: boolean,
    starting_health: number,
    light_secondary: table,
    secondary: table,
    light_primary: table,
    primary: table,
    primary_ability: table,
    secondary_ability: table
}

local GameOptions = {}

function GameOptions.new(overrideOptions: table?)
    local self: GameOptions = {
        min_players = 2,
        max_players = 2,
        round_length = 70,
        score_to_win_round = 1,
        score_to_win_game = 8,
        can_damage = true,
        restart_on_end = false,
        respawn_enabled = false,
        respawn_length = 3,
        buy_menu_enabled = false,
        buy_menu_add_instant = false,
        end_screen_length = 15,
        base_sc_earned = 30,
        base_xp_earned = 200,
        spawn_invincibility = 3,
        starting_shield = 50,
        starting_helmet = true,
        starting_health = 100,
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
        },
        light_secondary = {
            "glock17", "hkp30"
        },
        secondary = {
            "deagle"
        },
        light_primary = {
            "vityaz"
        },
        primary = {
            "ak103", "acr", "intervention"
        },
        primary_ability = {
            "Dash", "Satchel"
        },
        secondary_ability = {
            "LongFlash", "Molly", "HEGrenade", "SmokeGrenade"
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