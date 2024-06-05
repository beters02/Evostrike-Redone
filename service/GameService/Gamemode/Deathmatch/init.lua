local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local EvoPlayer = require(Framework.Module.EvoPlayer)
local GameServiceRemotes = Framework.Service.GameService.Remotes
local PostGameMap = ServerStorage:WaitForChild("PostGameMap")
local CharacterModel = game.StarterPlayer.StarterCharacter
local MedicalPackModel = ReplicatedStorage.Assets.Models.MedicalPack

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
        --ROUND_WAIT_TIME = 15,
        ROUND_WAIT_TIME = 3,
        OVERTIME_ENABLED = false,
        OVERTIME_SCORE_TO_WIN = 0,
        SCORE_TO_WIN = 0,

        BARRIERS_ENABLED = false,
        BARRIERS_LENGTH = 3,

        ROUND_END_CONDITION = "Timer",
        GAME_END_CONDITION = "TimerScore",
        
        SPECTATE_ENABLED = false, 
        PLAYER_SPAWN_ON_JOIN = true,
        RESPAWN_ENABLED = false,
        RESPAWN_LENGTH = 3,
        REQUIRE_REQUEST_JOIN = true,
        REQUIRE_PLAYERS_TO_BE_LOADED_START = false,

        --GAME_RESTART_LENGTH = 5,
        GAME_RESTART_LENGTH = 15,

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

        HEALTH_PICKUPS = true,
        HEALTH_PICKUP_LENGTH = 7,
        HEALTH_PICKUP_HEALTH_AMNT = 50,

        START_CAMERA_CFRAME_MAP = {
            default = CFrame.new(Vector3.new(543.643, 302.107, -37.932)) * CFrame.Angles(math.rad(-25.593), math.rad(149.885), math.rad(-0)),
            warehouse = CFrame.new(Vector3.new(543.643, 302.107, -37.932)) * CFrame.fromOrientation(-25.593, math.rad(149.885), -0)
        }
    }
}

local currentEndUIState = false

function Deathmatch:Start(service)
    print('Gamemode started!')
    self.CurrentHealthPickups = {}
end

function Deathmatch:Update(service)
    if service.GameStatus == "ENDED" then
        return
    end
    self:UpdateHealthPickups()
end

function Deathmatch:End(service)
    -- fade in players screen while we set up post match map
    Gamemode.CallUIFunctionAll(self, service, "GameEnd", "Start")
    currentEndUIState = "Start"

    -- destroy all health pickups
    for i, v in pairs(self.CurrentHealthPickups) do
        v.model:Destroy()
    end
    self.CurrentHealthPickups = {}

    Gamemode.ForceKillAllPlayers(self, service)
    AbilityService:ClearAllPlayerInventories()
    WeaponService:ClearAllPlayerInventories()

    preparePostMatchScreen(self, service)

    Gamemode.CallUIFunctionAll(self, service, "GameEnd", "MoveToMap")
    currentEndUIState = "MoveToMap"

    task.delay(3, function()
        tellModelsToWalk(self, service)
    end)

    print('Gamemode ended!')

    task.wait(self.GameOptions.GAME_RESTART_LENGTH)

    Gamemode.CallUIFunctionAll(self, service, "GameEnd", "Finish")
    currentEndUIState = false

    task.wait(1)

    if workspace:FindFirstChild("PostGameMap") then
        workspace.PostGameMap:Destroy()
    end
end

function Deathmatch:ForceEnd(service)
    Gamemode.CallUIFunctionAll(self, service, "PlayerDied", "Disable")
    Gamemode.ForceKillAllPlayers(self, service)
    AbilityService:ClearAllPlayerInventories()
    WeaponService:ClearAllPlayerInventories()
    if service.GameStatus == "ENDED" then
        Gamemode.CallUIFunctionAll(self, service, "GameEnd", "Finish")
    end
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

function Deathmatch:PlayerJoinedAfterGame(service, player)
    if not currentEndUIState then
        return
    end

    Gamemode.CallUIFunction(self, service, player, "GameEnd", "Start")
    if currentEndUIState == "MoveToMap" then
        Gamemode.CallUIFunction(self, service, player, "GameEnd", "MoveToMap")
    end
end

function Deathmatch:PlayerRemoved(service)
    print('Player removed!')
end

function Deathmatch:PlayerDied(service, died, killer, killNotRegistered)
    local canRespawnTime = tick() + self.GameOptions.RESPAWN_LENGTH

    -- ?????
    -- lemme remove this for now
    --[[if killNotRegistered then
        canRespawnTime = 0
    end]]

    self:CreateHealthPickup(died)

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

function Deathmatch:CreateHealthPickup(diedPlr)
    if not self.GameOptions.HEALTH_PICKUPS then
        return
    end

    local cf = diedPlr.Character.HumanoidRootPart.CFrame
    local model = MedicalPackModel:Clone()

    table.insert(self.CurrentHealthPickups, {model = model, endTick = tick() + self.GameOptions.HEALTH_PICKUP_LENGTH})
    local ind = #self.CurrentHealthPickups
    model:SetAttribute("PickupIndex", ind)
    CollectionService:AddTag(model, "HealthPack")

    local pickedUp = Instance.new("RemoteEvent", model)
    pickedUp.OnServerEvent:Connect(function(player)
        local dist = player.Character.HumanoidRootPart.CFrame.Position - model.PrimaryPart.CFrame.Position
        dist = dist.Magnitude
        if dist <= 10 then
            EvoPlayer:AddHealth(player.Character, self.GameOptions.HEALTH_PICKUP_HEALTH_AMNT)
            self.CurrentHealthPickups[ind] = nil
            model:Destroy()
        end
    end)

    model.Parent = workspace.Temp
    model.PrimaryPart.CFrame = cf --+ --Vector3.new(0,,0)
end

function Deathmatch:UpdateHealthPickups()
    for i, v in pairs(self.CurrentHealthPickups) do
        if tick() >= v.endTick then
            v.model:Destroy()
            self.CurrentHealthPickups[i] = nil
        end
    end
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

        for _, part in pairs(clone:GetChildren()) do
            if part:IsA("Part") or part:IsA("MeshPart") then
                part.CollisionGroup = "DeadCharacters"
            end
        end

        clone.PrimaryPart.Anchored = false
        clone.PrimaryPart.CFrame = map.Spawns[i].CFrame + Vector3.new(0,3,0)
        clone.PrimaryPart.CFrame = CFrame.new(clone.PrimaryPart.CFrame.Position) * (CFrame.fromOrientation(math.rad(-3.567), math.rad(-90.613), math.rad(0)):Inverse())
    end
end

function tellModelsToWalk(self, service)

    local bots = workspace.PostGameMap.Models:GetChildren()
    local botAnims = {}

    for i, v in pairs(bots) do
        botAnims[i] = {
            run = v.Humanoid:LoadAnimation(v.Humanoid.Animations.Run)
        }
        v.Humanoid:MoveTo(v.PrimaryPart.CFrame.Position + (v.PrimaryPart.CFrame.LookVector.Unit * 10))
    end

    service.Connections.ModelWalking = RunService.Heartbeat:Connect(function()
        for i, v in pairs(bots) do
            local vel = v.PrimaryPart.Velocity.Magnitude
            if vel >= 2 and not botAnims[i].run.IsPlaying then
                botAnims[i].run:Play()
            elseif vel < 2 and botAnims[i].run.IsPlaying then
                botAnims[i].run:Stop()
            end
        end
    end)
end

return Deathmatch