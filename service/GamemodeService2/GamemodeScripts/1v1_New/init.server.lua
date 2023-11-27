local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local EvoPlayer = require(Framework.Module.EvoPlayer)
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)

local Lib = Framework.Module.lib
local Promise = require(Lib.c_promise)
local Tables = require(Lib.fc_tables)

local GamemodeEvents = ReplicatedStorage.Services.GamemodeService2.Events["1v1"]
local PlayerDiedEvent = Framework.Module.EvoPlayer.Events.PlayerDiedRemote

local Options = require(script:WaitForChild("Options"))
local GameData = {Round = 1, Connections = {}, currentRoundStartTime = 0, currentRoundLength = 0}
local PlayerData = {Players = {_count = 0}}

local BarriersTemplate = script:WaitForChild("Barriers")
local Spawns = script:WaitForChild("Spawns")

Options.primary_weapons_combined = Tables.combine(Tables.clone(Options.primary), Tables.clone(Options.light_primary))
Options.secondary_weapons_combined = Tables.combine(Tables.clone(Options.secondary), Tables.clone(Options.light_secondary))

-- | Player Data |

PlayerData.Players._def = {Kills = 0, Deaths = 0, Score = 0, Player = false}

function PlayerData.Add(player)
    if not PlayerData.Players[player.Name] then
        PlayerData.Players[player.Name] = Tables.clone(PlayerData.Players._def)
        PlayerData.Players[player.Name].Player = player
        PlayerData.Players._count += 1
    end
end

function PlayerData.GetTotalPlayers()
    return PlayerData.Players._count
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

-- | Player Utility |

function getPlayerRoundContent() -- returns Spawns, Inventory, Health
    local spawns = {}
    local health = {starting_shield = 50, starting_health = 100, starting_helmet = true}
    local inv = {
        Weapons = {primary = false, secondary = false, ternary = "knife"},
        Abilities = {primary = "Dash", secondary = Options.secondary_ability[math.random(1,#Options.secondary_ability)]}
    }

    local spawnRandom = math.round(math.random(100, 200) / 100)
    spawns[1] = spawnRandom == 1 and 1 or 2
    spawns[2] = spawnRandom == 1 and 2 or 1

    if GameData.Round == 1 then
        health.starting_shield = 0
        health.starting_helmet = false
        inv.Weapons.secondary = Options.light_secondary[math.random(1,#Options.light_secondary)]
    elseif GameData.Round == 2 then
        health.starting_helmet = false
        inv.Weapons.secondary = Options.secondary[math.random(1,#Options.secondary)]
    elseif GameData.Round == 3 then
        inv.Weapons.primary = Options.light_primary[math.random(1,#Options.light_primary)]
        inv.Weapons.secondary = Options.secondary[math.random(1,#Options.secondary)]
    elseif GameData.Round == 4 then
        inv.Weapons.primary = Options.primary[math.random(1,#Options.primary)]
        inv.Weapons.secondary = Options.secondary[math.random(1,#Options.secondary)]
    else
        inv.Weapons.primary = Options.primary_weapons_combined[math.random(1,#Options.primary_weapons_combined)]
        inv.Weapons.secondary = Options.secondary_weapons_combined[math.random(1,#Options.secondary_weapons_combined)]
    end

    return spawns, inv, health
end

-- | Game |

function init()
    -- init current players
    for _, v in pairs(Players:GetPlayers()) do
        PlayerData.Add(v)
    end

    -- player initialized promise
    return Promise.new(function(resolve, reject, onCancel)
        local enough = PlayerData.GetTotalPlayers() >= 2

        local conn = Players.PlayerAdded:Connect(function(player)
            PlayerData.Add(player)
            enough = PlayerData.GetTotalPlayers() >= 2
        end)

        onCancel(function()
            conn:Disconnect()
        end)

        while not enough do
            task.wait()
        end

        resolve()
    end)
end

function main()
    print('Game Starting')

    -- init TopBar
    local _players = Players:GetPlayers()
    for i, player in pairs(_players) do
        local enemy = i == 1 and _players[2] or _players[1]
        GamemodeEvents.TopBarAdd:FireClient(player, enemy)
    end

    GameData.Connections.PlayerDiedMain = PlayerDiedEvent.OnServerEvent:Connect(function(player, killer)
        GamemodeEvents.PlayerDiedGui:FireClient(player, killer)
    end)

    return round()
end

function round()
    print('Round Starting')
    local barriers = BarriersTemplate:Clone()
    barriers.Parent = workspace

    -- prepare players via teleport, weapons, abilities
    local roundSpawns, roundInventory, roundHealth = getPlayerRoundContent()
    for i, v in pairs(Players:GetPlayers()) do
        v:LoadCharacter()
        v:WaitForChild("Character"):SetPrimaryPartCFrame(roundSpawns[i].CFrame + Vector3.new(0, 3, 0))
        v.Character:WaitForChild("Humanoid").Health = 100
        EvoPlayer:SetHelmet(v.Character, roundHealth.starting_helmet)
        EvoPlayer:SetShield(v.Character, roundHealth.starting_shield)
        for _, o in pairs(roundInventory.Weapons) do
            WeaponService:AddWeapon(v, o)
        end
        for _, o in pairs(roundInventory.Abilities) do
            AbilityService:AddAbility(v, o)
        end
    end

    -- begin round
    GamemodeEvents.TopBarTimerStart:FireAllClients(Options.barriers_length)

    -- set currentRoundVar for connecting clients
    GameData.currentRoundStartTime = tick()
    GameData.currentRoundLength = Options.barriers_length

    return Promise.delay(Options.barriers_length):andThen(function()
        -- [[ BARRIERS ]]
        barriers:Destroy()
        GamemodeEvents.TopBarTimerStart:FireAllClients(Options.round_length)
        print('Barriers Destroyed, Round Started!')
    end):andThen(Promise.race({
        -- [[ ROUND CONDITIONS ]]
        Promise.fromEvent(PlayerDiedEvent.OnServerEvent, function(player) -- Player 1 Died Condition (returns Condition, Winner, Loser)
            return player == Players:GetPlayers()[1]
        end):andThenReturn("PlayerDied", Players:GetPlayers()[2], Players:GetPlayers()[1]),

        Promise.fromEvent(PlayerDiedEvent.OnServerEvent, function(player) -- Player 2 Died Condition
            return player == Players:GetPlayers()[2]
        end):andThenReturn("PlayerDied", Players:GetPlayers()[1], Players:GetPlayers()[2]),

        Promise.delay(Options.round_length):andThenReturn("Timer") -- Timer Ended Condition
    }):andThen(function(result, winner, loser)
        -- [[ HANDLE ROUND END ]]
        GameData.Round += 1

        if result == "PlayerDied" then
            GamemodeEvents.TopBarTimerStart:FireAllClients(false)
            PlayerData.IncrementVar(winner, "Score", 1)
            PlayerData.IncrementVar(winner, "Kills", 1)
            PlayerData.IncrementVar(loser, "Deaths", 1)
            GamemodeEvents.TopBarChangeScore:FireAllClients({[winner.Name] = winner.Score})
            if PlayerData.GetVar(winner, "Score") >= Options.score_to_win then
                return true, result, winner, loser
            end
        end

        task.wait(1)
        return round()
    end))
end

function finish(winner, loser)
    for _, v in pairs(GameData.Connections) do
        v:Disconnect()
    end
end

-- | Linear Gamemode Script Start |

init()
:andThen(main)
:andThen(finish)