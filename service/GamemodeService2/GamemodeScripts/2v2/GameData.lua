-- Requires teamdata

export type GameDataStatus = "active" | "inactive"
export type BombStatus = "active" | "inactive" | "planting" | "defusing"

local teamdata = require(script.Parent:WaitForChild("TeamData"))

local gamedata
gamedata = {
    round = function() return teamdata.attackers.score + teamdata.defenders.score + 1 end,
    timeElasped = 0,
    canBuy = false,
    status = "inactive" :: GameDataStatus,
    bombStatus = "inactive" :: BombStatus,
    wasForceStart = false,
    teams = {defender = {}, attacker = {}} -- tracks players aliveness (defender.plr = {alive = true/false})
}

return gamedata