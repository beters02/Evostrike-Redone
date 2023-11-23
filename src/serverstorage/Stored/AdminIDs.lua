local RunService = game:GetService("RunService")
local module = {}
module.admins = {21877101, 116360953, 17648696, 436587030, 4904406825}
module.playtesters = {3268320054, 195532543, 409986024, 3393977735, 189284282, 852071685, 128415983, 11171879}

-- Check if player is above the default permission group
function module:IsHigherPermission(player: Player)
    if RunService:IsStudio() and (player.Name == "Player1" or player.Name == "Player2") then
        return true, "admin"
   end
   if table.find(module.admins, player.UserId) then
       return true, "admin"
   end
   if table.find(module.playtesters, player.UserId) then
       return true, "playtester"
   end
end

function module:IsAdmin(player: Player)
    local high, group = module:IsHigherPermission(player)
    return high and group == "admin"
end

function module:IsPlaytester(player: Player)
    local high, group = module:IsHigherPermission(player)
    return high and group == "playtester"
end

return module