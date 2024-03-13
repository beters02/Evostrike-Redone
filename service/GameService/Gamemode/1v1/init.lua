local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local ConnectionsLib = require(Framework.Module.lib.fc_rbxsignals)
local EvoPlayer = require(Framework.Module.EvoPlayer)
local GameServiceRemotes = Framework.Service.GameService.Remotes
local PostGameMap = ServerStorage:WaitForChild("PostGameMap")
local CharacterModel = game.StarterPlayer.StarterCharacter
local Tables = require(Framework.Module.lib.fc_tables)

local Gamemode = require(script.Parent)
local GM1v1 = {
    GameOptions = {
        MIN_PLAYERS = 1,
        MAX_PLAYERS = 2,

        TEAMS_ENABLED = false,
        TEAM_SIZE = 0,

        MAX_ROUNDS = 14,
        ROUND_LENGTH = 60,
        ROUND_WAIT_TIME = 3,
        OVERTIME_ENABLED = false,
        OVERTIME_SCORE_TO_WIN = 0,
        SCORE_TO_WIN = 7,

        BARRIERS_ENABLED = true,
        BARRIERS_LENGTH = 5,

        ROUND_END_CONDITION = "PlayerKilled",
        GAME_END_CONDITION = "PlayerScore",
        
        SPECTATE_ENABLED = false,
        PLAYER_SPAWN_ON_JOIN = false,
        RESPAWN_ENABLED = false,
        RESPAWN_LENGTH = 3,
        REQUIRE_REQUEST_JOIN = false,

        REQUIRE_PLAYERS_TO_BE_LOADED_START = true,

        --GAME_RESTART_LENGTH = 5,
        GAME_RESTART_LENGTH = 15,

        START_INVENTORY = {
            ABILITIES = {primary = "Dash", secondary = "LongFlash"},
            WEAPONS = {primary = "ak103", secondary = "glock17"}
        },

        MENU_TYPE = "1v1",
        BUY_MENU_ENABLED = true,
        BUY_MENU_ADD_INSTANT = false,

        START_HEALTH = 100,
        START_SHIELD = 50,
        START_HELMET = true,
        SPAWN_INVINCIBILITY = 3,

        START_CAMERA_CFRAME_MAP = {
            default = CFrame.new(Vector3.new(543.643, 302.107, -37.932)) * CFrame.Angles(math.rad(-25.593), math.rad(149.885), math.rad(-0)),
            warehouse = CFrame.new(Vector3.new(543.643, 302.107, -37.932)) * CFrame.fromOrientation(-25.593, math.rad(149.885), -0)
        }
    }
}

local InventoryDefs = {
    light_primary = {"vityaz"},
    light_secondary = {"hkp30", "glock17"},
    heavy_primary = {"ak103", "acr"},
    heavy_secondary = {"deagle"},

    ability_primary = {"Dash"},
    ability_secondary = {"LongFlash", "SmokeGrenade", "HEGrenade", "Molly"}
}
InventoryDefs.primary = Tables.combineNew(InventoryDefs.light_primary, InventoryDefs.heavy_primary)
InventoryDefs.secondary = Tables.combineNew(InventoryDefs.light_secondary, InventoryDefs.heavy_secondary)

local RoundInventories = {
    [1] = {primary = false, secondary = "light_secondary"},
    [2] = {primary = false, secondary = "heavy_secondary"},
    [3] = {primary = "light_primary", secondary = "heavy_secondary"},
    [4] = {primary = "heavy_primary", secondary = "secondary"},
    [5] = {primary = "primary", secondary = "secondary"}
}

local function getPlayerRoundInventory(round)
    local roundInv = Tables.clone(RoundInventories[round])
    print(round)
    print(roundInv)

    for i, v in pairs(roundInv) do
        if not v then
            continue
        end

        local possibleWeaponsInSlot = InventoryDefs[roundInv[i]]
        roundInv[i] = possibleWeaponsInSlot[math.random(1, #possibleWeaponsInSlot)]
    end

    local abilityPrimary = InventoryDefs.ability_primary[math.random(1, #InventoryDefs.ability_primary)]
    local abilitySecondary = InventoryDefs.ability_secondary[math.random(1, #InventoryDefs.ability_secondary)]
    return {
        ABILITIES = {primary = abilityPrimary, secondary = abilitySecondary},
        WEAPONS = {primary = roundInv.primary, secondary = roundInv.secondary}
    }
end

function GM1v1:Start(service)
    print('Gamemode started!')
end

function GM1v1:End(service)
end

function GM1v1:ForceEnd(service)
end

function GM1v1:InitPlayer(service, player)
end

function GM1v1:PlayerAdded(service, player)
end

function GM1v1:PlayerRemoved(service)
end

function GM1v1:PlayerDied(service, died, killer, killNotRegistered)
end

function GM1v1:RoundStart(service)
    Gamemode.CallUIFunctionAll(self, service, "TopBar", "Enable", service.GameOptions.BARRIERS_LENGTH - service.TimeElapsed)

    local round = service.CurrentRound
    local inventory = getPlayerRoundInventory(round)
    local spawns = service.Spawns:GetChildren()

    for i, v in pairs(service.PlayerData:GetPlayers()) do
        service.PlayerData:Set(v, "inventory", inventory)
        self:SpawnPlayer(service, v, spawns[i].CFrame + Vector3.new(0,2,0))
    end
end

function GM1v1:BarriersFinished(service)
    Gamemode.CallUIFunctionAll(self, service, "TopBar", "StartTimer", service.GameOptions.ROUND_LENGTH - service.TimeElapsed)
end

function GM1v1:RoundEnd(service, result, winner)
end

function GM1v1:SpawnPlayer(service, player, cframe)

    -- wait for player to be loaded
    if not player:GetAttribute("Loaded") then
        local conn
        conn = player:GetAttributeChangedSignal("Loaded"):Connect(function()
            self:SpawnPlayer(service, player, cframe)
            conn:Disconnect()
        end)
        return
    end

    player:LoadCharacter()
    task.wait()

    -- grab point, set health, add inventory
    local char = player.Character or player.CharacterAdded:Wait()
    self:InitCharacter(service, player, char, cframe)

    print('Player spawned!')
end

function GM1v1:InitCharacter(service, player, char, cframe)
    char:WaitForChild("HumanoidRootPart").CFrame = cframe
    print(cframe)
    print(char.HumanoidRootPart.CFrame)
    EvoPlayer:SetSpawnInvincibility(char, true, service.GameOptions.SPAWN_INVINCIBILITY)
    Gamemode.SetPlayerHealth(self, service, char)

    if player then
        Gamemode.AddPlayerInventory(self, service, player)
    end
end

function GM1v1:PlayerJoinedDuringRound(service, player)
    print('Player joined during round!')
end

return GM1v1