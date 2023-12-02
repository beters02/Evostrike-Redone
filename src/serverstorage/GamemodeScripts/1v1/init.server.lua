local Players = game:GetService("Players")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)

local Lib = Framework.Module.lib
local Promise = require(Lib.c_promise)
local Tables = require(Lib.fc_tables)
local EvoPlayer = require(Framework.Module.EvoPlayer)

local GamemodeEvents = ReplicatedStorage.GamemodeEvents
local _playerDiedEvent = Framework.Module.EvoPlayer.Events.PlayerDiedRemote
local PlayerDiedBindable = script:WaitForChild("Events"):WaitForChild("PlayerDied")
local Spawns = script:WaitForChild("Spawns")
local Barriers = script:WaitForChild("Barriers")

local GameData = {Round = 1, Connections = {}, currentRoundStartTime = 0, currentRoundLength = 0, isActive = false}
local PlayerData = {Players = {_count = 0}}
local Options = require(script:WaitForChild("Options"))
Options.primary_weapons_combined = Tables.combine(Tables.clone(Options.primary), Tables.clone(Options.light_primary))
Options.secondary_weapons_combined = Tables.combine(Tables.clone(Options.secondary), Tables.clone(Options.light_secondary))

-- | Player Data |

PlayerData.Players._def = {Kills = 0, Deaths = 0, Score = 0, Player = false}

function PlayerData.Add(player)
    if not PlayerData.Players[player.Name] then
        GamemodeEvents.HUD.INIT:FireClient(player, "1v1")
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
    spawns[1] = Spawns[spawnRandom == 1 and 1 or 2]
    spawns[2] = Spawns[spawnRandom == 1 and 2 or 1]

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
        GamemodeEvents.HUD.START:FireClient(player, enemy)
    end

    GameData.Connections.PlayerDiedMain = _playerDiedEvent.OnServerEvent:Connect(function(player, killer)
        if GameData.isActive then
            PlayerDiedBindable:Fire(player, killer)
        end
    end)

    task.wait(0.5)

    return round()
end

function round()
    print('Round Starting')

    GameData.isActive = true

    -- spawn barriers
    local barriers = Barriers:Clone()
    barriers.Parent = workspace

    -- prepare players via teleport, weapons, abilities
    local roundSpawns, roundInventory, roundHealth = getPlayerRoundContent()
    for i, v: Player in pairs(Players:GetPlayers()) do
        GamemodeEvents.HUD.ChangeRound:FireClient(v, GameData.Round) -- Change Round HUD
        task.spawn(function()
            v:LoadCharacter()

            task.wait()
            local char = v.Character or v.CharacterAdded:Wait()

            char:SetPrimaryPartCFrame(roundSpawns[i].CFrame + Vector3.new(0, 3, 0))
            char:WaitForChild("Humanoid").Health = 100
            EvoPlayer:SetHelmet(v.Character, roundHealth.starting_helmet)
            EvoPlayer:SetShield(v.Character, roundHealth.starting_shield)

            for _, o in pairs(roundInventory.Weapons) do
                if o then
                    WeaponService:AddWeapon(v, o)
                end
            end
            for _, o in pairs(roundInventory.Abilities) do
                if o then
                    AbilityService:AddAbility(v, o)
                end
            end
        end)
    end

    task.wait(0.5)

    -- begin round timer (fire at same time)
    GamemodeEvents.HUD.StartTimer:FireAllClients(Options.barriers_length)

    -- set currentRoundVar for connecting clients
    GameData.currentRoundStartTime = tick()
    GameData.currentRoundLength = Options.barriers_length

    task.wait(Options.barriers_length)
    barriers:Destroy()
    GamemodeEvents.HUD.StartTimer:FireAllClients(Options.round_length)
    print('Barriers Destroyed, Round Started!')

    local winner
    local loser

    return Promise.race({
        Promise.fromEvent(PlayerDiedBindable.Event, function(died, killer) -- Player 1 Died Condition (returns Condition, Winner, Loser)
            winner = killer
            loser = died
            return true
        end):andThenReturn("PlayerDied", winner, loser),

        Promise.delay(Options.round_length):andThenReturn("Timer") -- Timer Ended Condition
    })
    :andThen(function(result)
        -- [[ HANDLE ROUND END ]]
        GameData.isActive = false
        GameData.Round += 1

        if result == "PlayerDied" then
            GamemodeEvents.HUD.StartTimer:FireAllClients(false) -- stop timer
            PlayerData.IncrementVar(winner, "Score", 1)
            PlayerData.IncrementVar(winner, "Kills", 1)
            PlayerData.IncrementVar(loser, "Deaths", 1)

            local winnerScore = PlayerData.GetVar(winner, "Score")
            GamemodeEvents.HUD.ChangeScore:FireAllClients({[winner.Name] = winnerScore})
            
            if winnerScore >= Options.score_to_win then
                return true, result, winner, loser
            end
        end

        task.wait(1)
        return round()
    end)
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