local Lobby = {
    minimumPlayers = 1,
    isWaiting = false,

    status = "running"
}

local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)
local BotModule = require(Framework.sm_bots.Location)
local GamemodeLoc = game:GetService("ServerScriptService"):WaitForChild("gamemode"):WaitForChild("class"):WaitForChild("Lobby")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")
local QueueService = require(Framework.sm_queueService.Location)

function Lobby:PostWait(players)
    -- add any players that have already joined
    for i, v in pairs(players) do
        task.spawn(function()
            self:SpawnPlayer(v)
        end)
    end

    -- init player added connection
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:SpawnPlayer(player)
    end)

    -- remove barriers
    if workspace:FindFirstChild("Barriers") then
        workspace.Barriers.Parent = game:GetService("ReplicatedStorage")
    end

    -- start queue service
    QueueService:Start()

end

function Lobby:Start()

    self.nextUpdateTick = tick()
    self.serverInfoUpdateConn = RunService.Heartbeat:Connect(function()
        if tick() >= self.nextUpdateTick then
            self.nextUpdateTick = tick() + 5
            MessagingService:PublishAsync("ServerInfo", {PlaceID = game.PlaceId, JobID = game.JobId, Gamemode = self.Name})
        end
    end)

    local min = self.minimumPlayers or 1

    self.waitingThread = false
    if #Players:GetPlayers() < min then
        self.waitingThread = task.spawn(function()
            repeat
                task.wait(1)
            until #Players:GetPlayers() >= min
            self:PostWait(Players:GetPlayers())
        end)
        return
    end

    self:PostWait(Players:GetPlayers())
    print("Gamemode " .. self.currentGamemode .. " started!")
end

function Lobby:Stop()

    -- set status
    self.status = "dead"

    -- disconnect connections
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    if self.isWaiting then
        coroutine.yield(self.waitingThread)
        return
    end
    self.serverInfoUpdateConn:Disconnect()

    -- remove all weapons and abilities
    Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()

    -- unload all characters
    for i, v in pairs(Players:GetPlayers()) do
        v.Character.Humanoid:TakeDamage(1000)
        v.Character = nil
    end

    -- clear temps
    for i, v in pairs(workspace:WaitForChild("Temp"):GetChildren()) do
        v:Destroy()
    end

    for i, v in pairs(ReplicatedStorage:WaitForChild("temp"):GetChildren()) do
        v:Destroy()
    end

    -- destroy bots
    for i, v in pairs(CollectionService:GetTagged("Bot")) do
        task.spawn(function()
            v.Humanoid:TakeDamage(1000)
            task.wait(0.1)
            v:Destroy()
        end)
    end

    task.wait(0.1)

    print('Gamemode Lobby Stopped')
end

function Lobby:SpawnPlayer(player)
    task.spawn(function()
        if not player:GetAttribute("Loaded") then
            repeat task.wait() until player:GetAttribute("Loaded")
        end
    
        player:LoadCharacter()
        task.wait()
        
        local hum = player.Character:WaitForChild("Humanoid")
        player.Character.Humanoid.Health = 100
    
        -- teleport player to spawn
        local spawnLoc = GamemodeLoc:WaitForChild("Spawns"):WaitForChild("Default")
        player.Character.PrimaryPart.Anchored = true
        player.Character:SetPrimaryPartCFrame(CFrame.new(spawnLoc.CFrame.Position + Vector3.new(0,2,0)) * CFrame.Angles(0, math.rad(180), 0))
        player.Character.PrimaryPart.Anchored = false
    
        Ability.Add(player, "Dash")
        Weapon.Add(player, "Knife", true)
    
        local conn
        conn = hum:GetPropertyChangedSignal("Health"):Connect(function()
            if self.status ~= "running" then conn:Disconnect() return end
            if hum.Health <= 0 then self:Died(player) conn:Disconnect() return end
            if hum.Health < 100 then hum.Health = 100 return end
        end)
    end)
end

function Lobby:Died(player)
    task.spawn(function()
        Weapon.ClearPlayerInventory(player)
        Ability.ClearPlayerInventory(player)
    end)
    task.wait(2)
    self:SpawnPlayer(player)
end

return Lobby