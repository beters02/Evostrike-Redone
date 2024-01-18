-- Gamemode's Stored PlayerData

function clone(tbl)
    local c = {}
    for i, v in pairs(tbl) do
        if type(v) == "table" then
            c[i] = clone(v)
            continue
        end
        c[i] = v
    end
    return c
end

local options = require(script.Parent.GameOptions)

local playerdata
playerdata = {
    _stored = {},
    _bots = {},
    _count = 0,
    _def = {
        plr = "",
        kills = 0,
        deaths = 0,
        money = options.STARTING_MONEY,
        team = "",
        inventory = {
            weapons = {primary = false, secondary = options.STARTING_SECONDARY_WEAPON_ATTACKER},
            abilities = {primary = false, secondary = false}, -- abilitySlot = {name = abilityName, amount = amountOwned}
            equipment = {shield = false, helmet = false, defuser = false} -- shield = amnt or false
        }
    },
    _add = function(player)
        if not playerdata._stored[player.Name] then
            playerdata._count += 1
        end
        playerdata._stored[player.Name] = clone(playerdata._def)
        playerdata._stored[player.Name].plr = player
    end,
    _remove = function(player)
        if playerdata._stored[player.Name] then
            playerdata._count -= 1
        end
        playerdata._stored[player.Name] = nil
    end,
    _get = function(player, key: string?)
        if not key then
            return playerdata._stored[player.Name]
        end
        return playerdata._stored[player.Name][key]
    end,
    _inc = function(player, key, amnt)
        playerdata._stored[player.Name][key] += amnt
    end,
    _dec = function(player, key, amnt)
        playerdata._stored[player.Name][key] -= amnt
    end,

    --@summary Automatically sets inventory secondary weapon based on team if team is set
    _set = function(player, key: string?, new)
        if key then
            playerdata._stored[player.Name][key] = new
            if key == "team" then
                playerdata._stored[player.Name].inventory.weapons.secondary = options["STARTING_SECONDARY_WEAPON_" .. string.upper(new)]
            end
            return
        end
        playerdata._stored[player.Name] = new
    end
}

return playerdata