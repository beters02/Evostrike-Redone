local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Options = require(script.Parent:WaitForChild("Options"))
local Tables = require(Framework.Module.lib.fc_tables)

local PlayerData = {
    Players = {
        _count = 0,
        _def = {
            Kills = 0,
            Deaths = 0,
            Score = 0,
            Player = false,
            Inventory = false
        }
    }
}

function PlayerData.Add(player)
    if not PlayerData.Players[player.Name] then

        PlayerData.Players[player.Name] = Tables.clone(PlayerData.Players._def)
        PlayerData.Players[player.Name].Player = player
        PlayerData.Players[player.Name].Inventory = Tables.clone(Options.inventory)

        PlayerData.Players._count += 1
        return true
    end
    return false
end

function PlayerData.GetTotalPlayers()
    return PlayerData.Players._count
end

function PlayerData.SetInventorySlot(player, inventory, slot, new)
    PlayerData.Players[player.Name].Inventory[inventory][slot] = new
end

function PlayerData.GetVar(player, index)
    return PlayerData.Players[player.Name][index]
end

function PlayerData.SetVar(player, index, value)
    PlayerData.Players[player.Name][index] = value
end

function PlayerData.IncrementVar(player, index, value)
    PlayerData.Players[player.Name][index] += value
end

return PlayerData