local module = {}
module.stored = {"EPIXPLODE", "PetersNolan505", "NolanPeters505", "beters", "commanderfox201", "Fontainelocke", "LemonDaunger", "Player1", "Player2"}

function module:IsAdmin(player)
    if table.find(module.stored, player.Name) then
        return true
    end
    return false
end

return module