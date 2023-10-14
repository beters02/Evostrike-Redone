type PlayerData = {Player: Player, Kills: number, Deaths: number, Score: number, Money: number, Round: PlayerRoundData, Inventory: Inventory}
type PlayerRoundData = {Kills: number, Deaths: number}
type SubInventory = {primary: string | false, secondary: string | false, ternary: string | false}
type Inventory = {
    Weapons: SubInventory,
    Abilities: SubInventory
}

local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Timer = require(script:WaitForChild("Timer"))
local GameOptions = require(script:WaitForChild("GameOptions")).new()
local ConnsLib = require(Framework.Module.lib.fc_rbxsignals)

-- [[ GAME SCOPE ]]
local GameData = {Timer = false, CurrentRound = false, Connections = {}}
local PlayerData = {stored = {}}
local TeamData = {T = {}, CT = {}}

function Start()
    for _, v in pairs(Players:GetPlayers()) do
        PlayerData.Init(v)
    end

    if PlayerGetCount() < GameOptions.min_players then
        ConnsLib.TableConnect(PlayerData.Connections, "PlayerAdded", Players.PlayerAdded:Connect(function(player)
            PlayerData.Init(player)
        end))
    end

    --[[ConnsLib.TableConnect(PlayerData, "PlayerAdded", Players.PlayerAdded:Connect(function(player)
        -- get if player was on server?
    end))]]

    ConnsLib.SmartDisconnect(PlayerData.Connections.PlayerAdded)

    RoundStart(1)
end

function RoundStart(round: number)
    GameData.Timer = Timer.new(GameOptions.barriers_length)
    GameData.Timer:Start()
    task.spawn(function()
        GameData.Timer.Finished.Event:Wait()
        GameData.Timer:Destroy()
        GameData.Timer = Timer.new(GameOptions.round_length)
        -- destroy barriers
    end)
end

-- [[ PLAYER SCOPE ]]
function PlayerSpawn(player)
    
end

function PlayerGetCount()
    local count = 0
    for _, _ in pairs(PlayerData) do
        count += 1
    end
    return count
end

-- [[ PLAYER DATA SCOPE ]]
function PlayerData.Init(player: Player)
    if PlayerData.stored[player.Name] then
        return false
    end

    PlayerData.stored[player.Name] = {
        Player = player,
        Kills = 0,
        Deaths = 0,
        Score = 0,
        Round = {Kills = 0, Deaths = 0}::PlayerRoundData,
        Inventory = {Weapons = {primary = false, secondary = false, ternary = "knife"}, {primary = false, secondary = false}}
    }:: PlayerData
    return PlayerData.stored[player.Name]
end

function PlayerData.Get(player: Player)
    if not PlayerData.stored[player.Name] then
        repeat task.wait(0.2) until PlayerData.stored[player.Name]
    end
    return PlayerData.stored[player.Name]
end

function PlayerData.Increment(player: Player, key: "Kills" | "Deaths" | "Score", amnt: number)
    PlayerData.Get(player)
    PlayerData.stored[player.Name][key] += amnt
end

function PlayerData.IncrementRound(player: Player, key: "Kills" | "Deaths", amnt: number)
    PlayerData.Get(player)
    PlayerData.stored[player.Name].Round[key] += amnt
end
--