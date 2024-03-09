--[[
    PlayerData is a Class that will be added to all Gamemodes. Use this to manage player's gamemode data

    Gamemode.PlayerData = PlayerData.new()
    Gamemode.PlayerData:AddPlayer(player)
    Gamemode.PlayerData:Increment(player, "kills", 1)
    local PlayerKills = Gamemode.PlayerData:Get(player, "kills")
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(Framework.Module.lib.fc_tables)

local PlayerData = {}
PlayerData.__index = PlayerData

function PlayerData.new()
    local self = setmetatable({}, PlayerData)
    self.Players = {}

    self.DefaultData = {
        score = 0,
        kills = 0,
        deaths = 0,
        money = 0,
        inventory = {
            weapon = { primary = "ak103", secondary = "glock17" },
            ability = { primary = "dash", secondary = "longFlash" }
        }
    }
    
    return self
end

function PlayerData:AddPlayer(player)
    if self.Players[player.Name] then
        warn("Player " .. tostring(player.Name) .. " already exists in PlayerData. Overriding data.")
    end

    self.Players[player.Name] = Tables.clone(self.DefaultData)
end

function PlayerData:RemovePlayer(player)
    if self.Players[player.Name] then
        self.Players[player.Name] = nil
    end
end

function PlayerData:GetPlayer(player)
    return self.Players[player.Name]
end

function PlayerData:GetPlayers()
    local players = {}
    for playerName in self.Players do
        if not Players[playerName] then
            continue
        end
        table.insert(players, Players[playerName])
    end
    return players
end

function PlayerData:Get(player, key)
    if self.Players[player.Name] then
        return self.Players[player.Name][key]
    end
    return nil
end

function PlayerData:Set(player, key, value)
    if self.Players[player.Name] then
        self.Players[player.Name][key] = value
        return
    end
    warn("Did not set PlayerData key" .. tostring(player.Name) .. " PlayerData does not exist.")
end

function PlayerData:Increment(player, key, amnt)
    if self.Players[player.Name] then
        self.Players[player.Name][key] += amnt
        return
    end
    warn("Did not increment PlayerData key" .. tostring(player.Name) .. " PlayerData does not exist.")
end

function PlayerData:Decrement(player, key, amnt)
    if self.Players[player.Name] then
        self.Players[player.Name][key] -= amnt
        return
    end
    warn("Did not decrement PlayerData key" .. tostring(player.Name) .. " PlayerData does not exist.")
end

function PlayerData:Insert(player, key, value)
    if self.Players[player.Name] then
        table.insert(self.Players[player.Name][key], value)
        return
    end
    warn("Did not insert to PlayerData key" .. tostring(player.Name) .. " PlayerData does not exist.")
end

return PlayerData