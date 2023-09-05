local module = {}
module.admins = {"EPIXPLODE", "PetersNolan505", "NolanPeters505", "beters", "Player1", "Player2", "commanderfox201"}
module.playtesters = {"Fontainelocke", "LemonDaunger"}

function module:IsAdmin(player)
    if table.find(module.admins, player.Name) then
        return true, "admin"
    end
    if table.find(module.playtesters, player.Name) then
        return true, "playtester"
    end
    return false
end

return module