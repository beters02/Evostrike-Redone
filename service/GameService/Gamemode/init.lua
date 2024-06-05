-- [[ Base Gamemode Module ]]
--[[
    Each Gamemode Module is required to have a GameOptins table, as well as all of these functions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local ConnectionsLib = require(Framework.Module.lib.fc_rbxsignals)
local EvoPlayer = require(Framework.Module.EvoPlayer)

local GameServiceRemotes = ReplicatedStorage.Services.GameService.Remotes

local Gamemode = {
    GameOptions = {

        MIN_PLAYERS = 1,
        MAX_PLAYERS = 1,

        TEAMS_ENABLED = false,
        TEAM_SIZE = 0,

        MAX_ROUNDS = 1,
        ROUND_LENGTH = 60 * 5,
        ROUND_WAIT_TIME = 3,
        OVERTIME_ENABLED = false,
        OVERTIME_SCORE_TO_WIN = 0,
        SCORE_TO_WIN = 12,
        GAME_RESTART_LENGTH = 15,

        ROUND_END_CONDITION = "PlayerKilled",
        GAME_END_CONDITION = "Score",

        BARRIERS_ENABLED = false,
        BARRIERS_LENGTH = 3,

        REQUIRE_PLAYERS_TO_BE_LOADED_START = false,
        
        SPECTATE_ENABLED = true,
        PLAYER_SPAWN_ON_JOIN = true,
        REQUIRE_REQUEST_JOIN = true,
        RESPAWN_ENABLED = true,
        RESPAWN_LENGTH = 3,

        START_INVENTORY = {},

        MENU_TYPE = "Lobby",
        BUY_MENU_ENABLED = true,
        BUY_MENU_ADD_INSTANT = true,

        START_HEALTH = 100,
        START_SHIELD = 50,
        START_HELMET = true,
        SPAWN_INVINCIBILITY = 3,

        HEALTH_PICKUPS = false,
        HEALTH_PICKUP_HEALTH_AMNT = 50,

        START_CAMERA_CFRAME_MAP = {
            default = CFrame.new(Vector3.new(543.643, 302.107, -37.932)) * CFrame.Angles(math.rad(-25.593), math.rad(149.885), math.rad(-0)),
            warehouse = CFrame.new(Vector3.new(543.643, 302.107, -37.932)) * CFrame.fromOrientation(-25.593, math.rad(149.885), -0)
        }
    }
}

-- Required
function Gamemode:Start(service) end
function Gamemode:End(service) end
function Gamemode:PlayerAdded(service) end
function Gamemode:PlayerRemoved(service) end
function Gamemode:PlayerDied(service, died, killer, killNotRegistered) end
function Gamemode:RoundStart(service, round) end
function Gamemode:RoundEnd(service, result, ...) end
function Gamemode:SpawnPlayer(service, player) end -- Only called if player joins during round and PLAYER_SPAWN_ON_JOIN is true.
function Gamemode:PlayerJoinedDuringRound(service, player) end
function Gamemode:PlayerJoinedAfterGame(service, player) end
function Gamemode:TimerEnded(service, player) end -- Only called if ROUND_END_CONDITION or GAME_END_CONDITION is set to Custom.
function Gamemode:InitPlayer(service, player) end
function Gamemode:InitCharacter(service, player) end
function Gamemode:ForceEnd(service, player) end
function Gamemode:BarriersFinished(service) end -- Only called if BARRIERS_ENABLED = true
function Gamemode:Update() end

-- Not Required, shared access.

function Gamemode:SpawnAllPlayers(service)
    for _, v in pairs(service.PlayerData:GetPlayers()) do
        if service.GameOptions.REQUIRE_REQUEST_JOIN
        and not service.ServicePlayerData:Get(v, "joined") then
            continue
        end
        self:SpawnPlayer(service, v)
    end
end

function Gamemode:ForceKillAllPlayers(service)
    for _, v in pairs(service.PlayerData:GetPlayers()) do
        EvoPlayer:ForceKill(v)
    end
end

function Gamemode:AddPlayerInventory(service, player)
    local pd = service.PlayerData:GetPlayer(player)
    if player then
        WeaponService:AddWeapon(player, "knife")
        for slot, item in pairs(pd.inventory.WEAPONS) do
            if not item then continue end
            WeaponService:AddWeapon(player, item, slot == "primary")
        end
        for _, item in pairs(pd.inventory.ABILITIES) do
            if not item then continue end
            AbilityService:AddAbility(player, item)
        end
    end
end

function Gamemode:SetPlayerHealth(service, char, health, shield, helmet)
    health = health or service.GameOptions.START_HEALTH
    shield = shield or service.GameOptions.START_SHIELD
    helmet = helmet or service.GameOptions.START_HELMET
    char:WaitForChild("Humanoid").Health = health
    EvoPlayer:SetHelmet(char, helmet)
    EvoPlayer:SetShield(char, shield)
end

function Gamemode:SetUIGamemode(service, player, gamemode)
    GameServiceRemotes.SetUIGamemode:FireClient(player, gamemode)
end

function Gamemode:CallUIFunction(service, player, ui: string, func: string, ...)
    GameServiceRemotes.CallUIFunction:FireClient(player, ui, func, ...)
end

function Gamemode:CallUIFunctionAll(service, ui: string, func: string, ...)
    GameServiceRemotes.CallUIFunction:FireAllClients(ui, func, ...)
end

return Gamemode