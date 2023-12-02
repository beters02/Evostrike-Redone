local Players = game:GetService("Players")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)

local Lib = Framework.Module.lib
local Promise = require(Lib.c_promise)
local EvoPlayer = require(Framework.Module.EvoPlayer)

local GamemodeEvents = ReplicatedStorage.GamemodeEvents
local PlayerDiedRemote = Framework.Module.EvoPlayer.Events.PlayerDiedRemote
local BuyMenuSelectedEvent = ReplicatedStorage.Remotes.BuyMenuSelected

local Spawns = script:WaitForChild("Spawns")
local Barriers = script:WaitForChild("Barriers")

local GameData = {Connections = {}, isActive = false, currentRoundStartTime = false}
local Options = require(script:WaitForChild("Options"))
local PlayerData = require(script:WaitForChild("PlayerData"))

-- | Game |

function init()
    return Promise.new(function(resolve, reject, onCancel)
        for _, v in pairs(Players:GetPlayers()) do
            initPlayerAdd(v)
        end
        GameData.Connections.PlayerAddedMain = Players.PlayerAdded:Connect(function(player)
            initPlayerAdd(player)
        end)
        resolve()
    end)
end

function main()
    print('Game Starting')

    GameData.Connections.PlayerDiedMain = PlayerDiedRemote.OnServerEvent:Connect(function(player, killer)
        playerDied(player, killer)
    end)

    GameData.Connections.BuyMenu = BuyMenuSelectedEvent.OnServerEvent:Connect(function(_bmplayer, action, item, slot)
        if action == "AbilitySelected" then
            PlayerData.SetInventorySlot(_bmplayer, "Abilities", slot, item)
        elseif action == "WeaponSelected" then
            PlayerData.SetInventorySlot(_bmplayer, "Weapons", slot, item)
        end
    end)

    task.wait(0.5)
    return round()
end

function round()
    print('Round Starting')

    GameData.isActive = true

    resetAllPlayers()
    task.wait(0.5)
    GamemodeEvents.HUD.START:FireAllClients()

    -- set currentRoundVar for connecting clients
    GameData.currentRoundStartTime = tick()

    GamemodeEvents.HUD.StartTimer:FireAllClients(Options.round_length)
    return Promise.delay(Options.round_length)
end

function finish(winner, loser)
    for _, v in pairs(GameData.Connections) do
        v:Disconnect()
    end
end

-- | Player Main |

function initPlayerAdd(player)
    local didAdd = PlayerData.Add(player)
    if didAdd then
        GamemodeEvents.HUD.INIT:FireClient(player, "Deathmatch")
        if GameData.isActive then
            GamemodeEvents.HUD.START:FireClient(player)
            GamemodeEvents.HUD.StartTimer(Options.round_length - (tick() - (GameData.currentRoundStartTime or tick())))
        end
    end
end

function spawnPlayer(player)
    player:LoadCharacter()

    task.wait()
    local char = player.Character or player.CharacterAdded:Wait()
    local roundInventory = PlayerData.GetVar(player, "Inventory")

    char:SetPrimaryPartCFrame(getPlayerSpawnPointCF() + Vector3.new(0, 3, 0))
    char:WaitForChild("Humanoid").Health = 100
    EvoPlayer:SetHelmet(char, Options.starting_helmet)
    EvoPlayer:SetShield(char, Options.starting_shield)

    for _, o in pairs(roundInventory.Weapons) do
        if o then
            WeaponService:AddWeapon(player, o)
        end
    end
    for _, o in pairs(roundInventory.Abilities) do
        if o then
            AbilityService:AddAbility(player, o)
        end
    end
end

function playerDied(player, killer)
    GamemodeEvents.HUD.PlayerDied:FireClient(player, killer, GameData.isActive)
    if GameData.isActive then
        PlayerData.IncrementVar(player, "Deaths", 1)
        if killer then
            PlayerData.IncrementVar(killer, "Kills", 1)
        end
    end
end

-- | Player Main Extraction |

function resetAllPlayers() -- from Players:GetPlayers()
    WeaponService:ClearAllPlayerInventories()
    AbilityService:ClearAllPlayerInventories()
    for _, v in pairs(Players:GetPlayers()) do
        if v.Character then
            v.Character = nil
        end
    end
end

function getPlayerSpawnPointCF()
    local points = {}
    local lowest
    local spawns

    -- get spawn location in zones based on amount of players in game (disabled temporarily)
    spawns = Spawns.Zone1:GetChildren()

    for _, v in pairs(Players:GetPlayers()) do
        if not v.Character or v.Character.Humanoid.Health <= 0 then continue end

        for _, spwn in pairs(spawns) do
            if spwn:IsA("Part") then
                if not points[spwn.Name] then points[spwn.Name] = 10000 end
                points[spwn.Name] -= (v.Character:WaitForChild("HumanoidRootPart").CFrame.Position - spwn.CFrame.Position).Magnitude

                if not lowest or points[spwn.Name] < lowest[2] then
                    lowest = {spwn, points[spwn.Name]}
                end
            end
        end
    end

    lowest = lowest and lowest[1] or spawns[math.random(1, #spawns)]
    return lowest.CFrame
end

-- | Linear Gamemode Script Start |

init()
:andThen(main)
:andThen(finish)