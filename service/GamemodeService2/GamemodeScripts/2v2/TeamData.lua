local teamdata
teamdata = {
    attacker = {
        players = {}, -- Players keeps track of player aliveness (attackers.players.plr = {plr = Player, alive = true/false})
        score = 0
    },
    defender = {players = {}, score = 0}
}

return teamdata