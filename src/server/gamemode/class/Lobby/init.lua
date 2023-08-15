local Lobby = {
    minimumPlayers = 1,
    isWaiting = false
}

local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)
local BotModule = require(Framework.sm_bots.Location)
local GamemodeLoc = game:GetService("ServerScriptService"):WaitForChild("gamemode"):WaitForChild("class"):WaitForChild("Lobby")

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

    -- init bots
    for i, v in pairs(GamemodeLoc.Bots:GetChildren()) do
        BotModule:Add(v)
    end

    -- remove barriers
    if workspace:FindFirstChild("Barriers") then
        workspace.Barriers.Parent = game:GetService("ReplicatedStorage")
    end

    print('Loaded')
end

function Lobby:Start()
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

    -- disconnect connections
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    if self.isWaiting then
        coroutine.yield(self.waitingThread)
        return
    end

    -- remove all weapons and abilities
    Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()

    -- unload all characters
    for i, v in pairs(Players:GetPlayers()) do
        v.Character.Humanoid:TakeDamage(1000)
        v.Character = nil
    end

end

function Lobby:SpawnPlayer(player)
    player:LoadCharacter()

    task.wait()

    local hum = player.Character:WaitForChild("Humanoid")
    print(hum)

    player.Character.Humanoid.Health = 100

    -- teleport player to spawn
    local spawnLoc = workspace:WaitForChild("Spawns"):WaitForChild("Default")
    --[[local Spawns = workspace:FindFirstChild("Spawns")
    local spawnLoc = Spawns and Spawns:FindFirstChild("Default")]]
    spawnLoc = spawnLoc or workspace.SpawnLocation

    player.Character.PrimaryPart.Anchored = true
    player.Character:SetPrimaryPartCFrame(spawnLoc.CFrame + Vector3.new(0,2,0))
    player.Character.PrimaryPart.Anchored = false

    -- give player knife
    Ability.Add(player, "Dash")
    --Ability.Add(player, "Molly")
    Ability.Add(player, "LongFlash")
    Weapon.Add(player, "AK47")
    --Weapon.Add(player, "Glock17")
    Weapon.Add(player, "Knife", true)

    if player.Character.Humanoid.Health <= 0 then warn("what the fuck") end

    local conn
    conn = hum:GetPropertyChangedSignal("Health"):Connect(function()
        print(hum.Health)
        if hum.Health <= 0 then
            self:Died(player)
            conn:Disconnect()
        end
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