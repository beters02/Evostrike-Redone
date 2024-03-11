local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local ConnectionsLib = require(Framework.Module.lib.fc_rbxsignals)
local EvoPlayer = require(Framework.Module.EvoPlayer)
local GameServiceRemotes = Framework.Service.GameService.Remotes
local PostGameMap = ServerStorage:WaitForChild("PostGameMap")
local CharacterModel = game.StarterPlayer.StarterCharacter

local Gamemode = require(script.Parent)
local Deathmatch = {
    GameOptions = {
        MIN_PLAYERS = 1,
        MAX_PLAYERS = 4,

        TEAMS_ENABLED = false,
        TEAM_SIZE = 0,

        MAX_ROUNDS = 1,
        ROUND_LENGTH = 60 * 5,
        --ROUND_LENGTH = 15,
        ROUND_WAIT_TIME = 3,
        OVERTIME_ENABLED = false,
        OVERTIME_SCORE_TO_WIN = 0,
        SCORE_TO_WIN = 0,

        ROUND_END_CONDITION = "Timer",
        GAME_END_CONDITION = "TimerScore",
        
        SPECTATE_ENABLED = false, 
        PLAYER_SPAWN_ON_JOIN = true,
        RESPAWN_ENABLED = false,
        RESPAWN_LENGTH = 3,
        REQUIRE_REQUEST_JOIN = true,

        GAME_RESTART_LENGTH = 5,

        START_INVENTORY = {
            ABILITIES = {primary = "Dash", secondary = "LongFlash"},
            WEAPONS = {primary = "ak103", secondary = "glock17"}
        },

        MENU_TYPE = "Lobby",
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

function Deathmatch:Start(service)
    print('Gamemode started!')
end

function Deathmatch:End(service)
    -- fade in players screen while we set up post match map
    Gamemode.CallUIFunctionAll(self, service, "GameEnd", "Start")

    Gamemode.ForceKillAllPlayers(self, service)
    AbilityService:ClearAllPlayerInventories()
    WeaponService:ClearAllPlayerInventories()

    preparePostMatchScreen(self, service)

    Gamemode.CallUIFunctionAll(self, service, "GameEnd", "MoveToMap")

    print('Gamemode ended!')

    task.wait(self.GameOptions.GAME_RESTART_LENGTH)

    Gamemode.CallUIFunctionAll(self, service, "GameEnd", "Finish")

    task.wait(1)

    if workspace:FindFirstChild("PostGameMap") then
        workspace.PostGameMap:Destroy()
    end
end

function Deathmatch:InitPlayer(service, player)
    Gamemode.CallUIFunction(self, service, player, "BuyMenu", "Enable")
    Gamemode.CallUIFunction(self, service, player, "TopBar", "Enable", service.GameOptions.ROUND_LENGTH - service.TimeElapsed)
end

function Deathmatch:PlayerAdded(service, player)
    print('Player added!')
end

function Deathmatch:PlayerRemoved(service)
    print('Player removed!')
end

function Deathmatch:PlayerDied(service, died, killer, killNotRegistered)
    local canRespawnTime = tick() + self.GameOptions.RESPAWN_LENGTH
    if killNotRegistered then
        canRespawnTime = 0
    end

    Gamemode.CallUIFunction(self, service, died, "PlayerDied", "Enable", killer, self.GameOptions.RESPAWN_LENGTH)
    listenForPlayerSpawn(self, service, died, canRespawnTime)
    
    Gamemode.CallUIFunction(self, service, died, "TopBar", "UpdateScoreFrame", false, service.PlayerData:Get(died, "deaths"))

    if not killNotRegistered then
        Gamemode.CallUIFunction(self, service, killer, "TopBar", "UpdateScoreFrame", service.PlayerData:Get(killer, "kills"))
    end

    print('Player died!')
end

function Deathmatch:RoundStart(service, round)
    Gamemode.SpawnAllPlayers(self, service)
    print('Round started!')
end

function Deathmatch:RoundEnd(service, result)
    print('Round ended!')
end

function Deathmatch:SpawnPlayer(service, player)

    -- wait for player to be loaded
    if not player:GetAttribute("Loaded") then
        local conn
        conn = player:GetAttributeChangedSignal("Loaded"):Connect(function()
            self:SpawnPlayer(service, player)
            conn:Disconnect()
        end)
        return
    end

    if not service.PlayerData:Get(player, "alive") then
        Gamemode.CallUIFunction(self, service, player, "InitialPlayerSpawn", "SetStartCameraCF", service.GameOptions.START_CAMERA_CFRAME_MAP.warehouse)
        Gamemode.CallUIFunction(self, service, player, "InitialPlayerSpawn", "Enable")
        listenForPlayerSpawn(self, service, player)
        return
    end

    player:LoadCharacter()
    task.wait()

    -- grab point, set health, add inventory
    
    local char = player.Character or player.CharacterAdded:Wait()
    self:InitCharacter(service, player, char)

    print('Player spawned!')
end

function Deathmatch:InitCharacter(service, player, char)
    local cf = getPlayerSpawnPoint(service)
    char:WaitForChild("HumanoidRootPart").CFrame = cf + Vector3.new(0, 2, 0)
    EvoPlayer:SetSpawnInvincibility(char, true, service.GameOptions.SPAWN_INVINCIBILITY)
    Gamemode.SetPlayerHealth(self, service, char)

    if player then
        Gamemode.AddPlayerInventory(self, service, player)
    end
end

function Deathmatch:PlayerJoinedDuringRound(service, player)
    print('Player joined during round!')
end

-- Only called if ROUND_END_CONDITION or GAME_END_CONDITION is set to Custom.
function Deathmatch:TimerEnded(service, player)
end

-- [[ PLAYER SPAWNING ]]
function getPlayerSpawnPoint(service)
    local points = {}
    local lowest
    local spawns

    -- get spawn location in zones based on amount of players in game (disabled temporarily)
    spawns = service.Spawns.Zone1:GetChildren()

    for _, v in pairs(service.PlayerData:GetPlayers()) do
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

function listenForPlayerSpawn(self, service, player, canRespawnTime)
    -- wait for player to click spawn button.
    local spwnConnStr = player.Name .. "_Spawn"
    local waiting = false

    service.Connections[spwnConnStr] = GameServiceRemotes.PlayerSpawn.OnServerEvent:Connect(function(spawnPlr)
        if spawnPlr == player then

            if waiting then
                return
            end

            if canRespawnTime and tick() < canRespawnTime then
                waiting = true
                repeat task.wait() until tick() >= canRespawnTime
            end

            print('Spawning Player...')
            service.PlayerData:Set(player, "alive", true)
            self:SpawnPlayer(service, player)
            service.Connections[player.Name .. "_Spawn"]:Disconnect()
            service.Connections[player.Name .. "_Spawn"] = nil
        end
    end)

end

--[[ POST MATCH SCREEN ]]
function preparePostMatchScreen(self, service)
    local map = PostGameMap:Clone()
    map.Parent = workspace

    local players = service.PlayerData:GetPlayers()

    -- create player models
    for i = 1, #players do
        local clone = CharacterModel:Clone()
        clone.Parent = map.Models
        clone.PrimaryPart.Anchored = true
        clone.PrimaryPart.CFrame = map.Spawns[i].CFrame + Vector3.new(0,5,0)
    end
end


return Deathmatch