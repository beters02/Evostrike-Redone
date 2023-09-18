local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)
local GamemodeClasses = game:GetService("ServerScriptService"):WaitForChild("gamemode"):WaitForChild("class")
local CollectionService = game:GetService("CollectionService")
--local BotModule = require(game:GetService("ServerScriptService"):WaitForChild("bots"):WaitForChild("m_bots"))
local BotService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("BotService"))
local diedMainEvent = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")
local EvoMM = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("EvoMMWrapper"))

local Base = {
    minimumPlayers = 1,
    maximumPlayers = 8,
    startWithBarriers = false,
    playerDataEnabled = true,
    botsEnabled = false,
    queueServiceEnabled = false,
    respawnsEnabled = true,
    respawnLength = 2,
    startWithMenuOpen = false,

    shieldEnabled = true,
    startingShield = 50,
    startingHelmet = true,
    startingHealth = 100,

    objects = {
        baseLocation = GamemodeClasses:WaitForChild("Base"),
        moduleLocation = GamemodeClasses.Base,
        deathCameraScript = GamemodeClasses.Base.deathCamera,

        spawns = GamemodeClasses.Base.Spawns,
        bots = GamemodeClasses.Base.Bots
    },

    maps = {}, -- (init in m_gamemode) {mapName = mapID}

    status = "running",
    isWaiting = false,
    customDiedCallbacks = {},
    playerdata = {}
}

Base.__index = Base

-- Base Functions

function Base:Start()

    print("Gamemode " .. self.Name .. " started!")

    -- init current players (self.players)
    for _, player in pairs(Players:GetPlayers()) do
        self:InitPlayerData(player)
    end

    -- init player added connection
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:InitPlayerData(player)
    end)

    -- wait for min
    if #(self.players or game:GetService("Players"):GetPlayers()) < (self.minimumPlayers or 1) then
        self:WaitForMinimumPlayers(self.minimumPlayers or 1)
    end

    -- set new player added connection
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:InitPlayerData(player)
        self:SpawnPlayer(player)
        print('spawn plradd')
    end)

    -- spawn players
    for i, v in pairs(self.players or game:GetService("Players"):GetPlayers()) do
        task.spawn(function()
            self:SpawnPlayer(v)
            print('spawn initial')
        end)
    end

    -- init playerdata removing connection if necessary
    if self.playerDataEnabled then
        self.playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
            if self.playerdata[player.Name] then
                pcall(function()
                    for i, v in pairs(self.playerdata[player.Name].connections) do
                        v:Disconnect()
                    end
                end)
                self.playerdata[player.Name] = nil
                if self.players then
                    self.players[player.Name] = nil
                end
            end
        end)
    end

    -- init player died registration connection
    if self.playerDiedRegisterConn then self.playerDiedRegisterConn:Disconnect() end
    self.playerDiedRegisterConn = diedMainEvent.OnServerEvent:Connect(function(player)
        self:Died(player)
    end)

    -- init bots if necessary
    if self.botsEnabled then
        for i, v in pairs(self.objects.bots:GetChildren()) do
            BotService:AddBot({SpawnCFrame = v.PrimaryPart.CFrame, StartingHealth = self.startingHealth, StartingShield = self.shieldEnabled and self.startingShield or 0, StartingHelmet = self.startingHelmet or false})
        end
    end

    -- remove barriers if necessary
    if not self.startWithBarriers then
        if workspace:FindFirstChild("Barriers") then
            workspace.Barriers.Parent = game:GetService("ReplicatedStorage")
        end
    end

    -- start queue service
    if self.queueServiceEnabled then
        local gamemodes = {}
        for i, v in pairs(GamemodeClasses:GetChildren()) do
            if v:IsA("ModuleScript") and require(v).canQueue then
                table.insert(gamemodes, v.Name)
            end
        end
        EvoMM:StartQueueService(gamemodes)
    end
    
end

function Base:Stop()

    -- set status
    self.status = "dead"

    -- disconnect connections
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    if self.isWaiting then self.isWaiting = false end

    -- remove all queue'd players?

    -- remove all weapons and abilities
    Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()

    -- unload all characters
    for i, v in pairs(Players:GetPlayers()) do
        if v.Character and v.Character.Humanoid then
            v.Character.Humanoid:TakeDamage(1000)
        end
        
        v.Character = nil
    end

    -- clear temps (destroy grenades, bullets, etc)
    for i, v in pairs(workspace.Temp:GetChildren()) do
        v:Destroy()
    end

    -- clear playerdata instances
    self:ClearPlayerData()

    -- destroy bots
    BotService:RemoveAllBots()

    print('Gamemode Lobby Stopped')
end

function Base:ClearPlayerData()
    if self.playerdata then
        _playerDataRemovalRecurse(self.playerdata)
    end
end

function _playerDataRemovalRecurse(tab)
    for i, v in pairs(tab) do
        if type(v) == "table" then
            _playerDataRemovalRecurse(v)
            continue
        elseif typeof(v) == "Instance" then
            v:Destroy()
        elseif typeof(v) == "RBXScriptSignal" then
            v:Disconnect()
        end
    end
end

-- Force Start a gamemode with Bots filling in for the missing players
function Base:ForceStart()
    
    -- fill missing players with bots
    for i = 1, self.minimumPlayers - #(self.players or Players:GetPlayers()) do
        table.insert(self.players, BotService:AddBot({Respawn = true, RespawnLength = 0}))
        self:InitPlayerData(self.players[#self.players])
    end

end

-- Utility Functions

function Base:WaitForMinimumPlayers(min)
    repeat
        task.wait(0.5)
    until #(self.players or game:GetService("Players"):GetPlayers()) >= min
end

function Base:GetTotalPlayerCount()
    local _count = 0
    for i, v in pairs(self.playerDataEnabled and self.playerdata or Players:GetPlayers()) do
        if v then _count += 1 end
    end
    return _count
end

-- Player Functions

function Base:InitPlayerData(player)
    if not self.players then self.players = {} end
    self.playerdata[player.Name] = {deathCameraScript = false, isSpawned = false}
    if not table.find(self.players, player) then table.insert(self.players, player) end
end

function Base:SpawnPlayer(player)
    task.spawn(function()
        if not player:GetAttribute("Loaded") then
            repeat task.wait() until player:GetAttribute("Loaded")
        end

        -- start player with main menu open if necessary
        if self.startWithMenuOpen and not self.playerdata[player.Name].isSpawned then

            -- load character gui
            local remove = {}
            if not player.PlayerGui:FindFirstChild("MainMenu") then
                local _c
                for i, v in pairs(game:GetService("StarterGui"):GetChildren()) do
                    if v:IsA("ScreenGui") and v.Name ~= "HUD" and v.Name ~= "Stats" then
                        _c = v:Clone()
                        _c.Parent = player.PlayerGui
                    end
                end
            end

            local _c = Base.objects.baseLocation.openMenu:Clone()
            _c.Parent = player.PlayerGui

            player.PlayerGui:WaitForChild("MainMenu"):SetAttribute("NotSpawned", true)

            -- wait for player to ask to spawn
            local spwn = Instance.new("RemoteFunction", player.PlayerGui:WaitForChild("MainMenu"))
            spwn.Name = "SpawnRemote"

            local invoked = false

            spwn.OnServerInvoke = function()
                if invoked then return end
                invoked = true
                local succ, err = pcall(function()
                    self.playerdata[player.Name].isSpawned = true
                    player.PlayerGui:WaitForChild("MainMenu"):SetAttribute("NotSpawned", false)
                    self:SpawnPlayer(player)
                    print('spawn menu')
                    Debris:AddItem(_c, 1)
                end)
                invoked = false
                return succ, err
            end

            return
        end
        
        if self.playerdata[player.Name] and self.playerdata[player.Name].deathCameraScript then
            self.playerdata[player.Name].deathCameraScript:WaitForChild("Destroy"):FireClient(player)
        end

        player:LoadCharacter()
        task.wait()
        
        local hum = player.Character:WaitForChild("Humanoid")
        player.Character.Humanoid.Health = self.startingHealth
    
        -- teleport player to spawn
        local spawnLoc = self.objects.spawns.Default
        player.Character.PrimaryPart.Anchored = true
        player.Character:SetPrimaryPartCFrame(CFrame.new(spawnLoc.CFrame.Position + Vector3.new(0,2,0)) * CFrame.Angles(0, math.rad(180), 0))
        player.Character.PrimaryPart.Anchored = false
    
        Ability.Add(player, "Dash")
        Weapon.Add(player, "Knife", true)
        
        print('starting')

        local conn
        conn = hum:GetPropertyChangedSignal("Health"):Connect(function()
            if self.status ~= "running" then conn:Disconnect() return end
            if hum.Health <= 0 then self:Died(player) conn:Disconnect() return end
            if hum.Health < 100 then hum.Health = 100 return end
        end)
    end)
end

function Base:StartPlayer(player)
    if not player:GetAttribute("Loaded") then
        repeat task.wait() until player:GetAttribute("Loaded")
    end

    -- start player with main menu open
    print(self.Location)
    local _c = Base.objects.baseLocation.openMenu:Clone()
    _c.Parent = player.PlayerGui
    Debris:AddItem(_c, 5)
end

-- Died

function Base:Died(player)

    self:DiedCamera(player)
    self:DiedGui(player)

    task.spawn(function()
        Weapon.ClearPlayerInventory(player)
        Ability.ClearPlayerInventory(player)
    end)

    for _, extraDiedFunc in pairs(self.customDiedCallbacks) do
        extraDiedFunc(player)
    end

    if self.respawnsEnabled then
        task.wait(self.respawnLength)
        if self.status == "running" then
            self:SpawnPlayer(player)
            print('spawn died')
        end
    end

end

function Base:DiedCamera(player)
    local killer = player.Character:FindFirstChild("DamageTag") and player.Character.DamageTag.Value or player
    local camerac = self.objects.deathCameraScript:Clone()
    camerac:WaitForChild("killerObject").Value = killer
    camerac.Parent = player.Character
    self.playerdata[player.Name].deathCameraScript = camerac
end

function Base:DiedGui()
end

return Base