local RunService = game:GetService("RunService")
local module = {}
module.admins = {21877101, 116360953, 17648696, 436587030}
module.playtesters = {4904406825, 3268320054, 195532543, 409986024, 3393977735}

function module:IsAdmin(player: Player)
    if RunService:IsStudio() and (player.Name == "Player1" or player.Name == "Player2") then
         return true, "admin"
    end
    if table.find(module.admins, player.UserId) then
        return true, "admin"
    end
    if table.find(module.playtesters, player.UserId) then
        return true, "playtester"
    end
    return false
end

return module