local G1v1 = {
    minimumPlayers = 2,
    maximumPlayers = 2,
    roundLength = 120,
    roundsToWin = 7,
    overtimeRounds = 1,
    overtimeRoundLength = 60,

    isWaiting = false,
    currentRound = 1,
    roundStatus = "loading", -- loading, running, dead
    roundHotConnections = {},
    roundPlayerData = {},
    ended = nil
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")
local Ability = require(Modules:WaitForChild("Ability"))
local Weapon = require(Modules:WaitForChild("Weapon"))
local SetClientCameraPosEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Camera"):WaitForChild("SetPos")



--[[
    Game Loop
]]


-- Main Round Loop
function G1v1:RoundLoop(round: number)
    -- start the round and get the ended event
    local roundEnded = self:RoundStart(round)

    -- wait for the event to fire, get end condition
    local condition, winner, loser = roundEnded.Event:Wait()

    -- if game is over, stop loop
    local gameEnd = self:RoundEnd(condition, winner, loser)
    if gameEnd then
        self:GameEnd()
        return
    else -- otherwise, increment round and recurse
        self.currentRound += 1
        return G1v1:RoundLoop(self.currentRound)
    end
end


function G1v1:StartGameLoop()
    print("Gamemode " .. self.currentGamemode .. " started!")
    G1v1:RoundLoop(1)
end


--[[
    Base Gamemode Functions
]]


-- Start Function
local function Start(self, players)

    -- set var
    self.players = players
    self.currentRound = 1

    -- init player added connection
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    self.playerAddedConnection = Players.PlayerAdded:Connect(function(player) end) --TODO: spectate

    -- init playerdata
    for i, v in pairs(self.players) do
        self.roundPlayerData[v.Name] = {
            kills = 0,
            deaths = 0,
            roundWins = 0,
            totaldmg = 0,
            rounddmg = 0,
        }
    end

    -- init round 1
    self:StartGameLoop()
    
end


-- Start Waiting function
function G1v1:Start()
    local min = self.minimumPlayers or 1

    self.waitingThread = false
    local p = Players:GetPlayers()
    if #p < min then
        local un = Vector3.new(-29.61, -53.521, -0).Unit
        SetClientCameraPosEvent:FireClient(p[1], false, CFrame.new(Vector3.new(46.167, 41.093, -102.603)) * CFrame.Angles(un.X, un.Y, 0))
        self.waitingThread = task.spawn(function()
            repeat
                task.wait(1)
            until #Players:GetPlayers() >= min
            Start(self, Players:GetPlayers())
            return
        end)
        return
    end

    Start(self, Players:GetPlayers())
end


-- ForceStop
function G1v1:Stop()

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


-- CharacterAdded Function
function G1v1:SpawnPlayer(player)
    player:LoadCharacter()
    local character = player.Character or player.CharacterAdded:Wait()

    -- connect death events
    character.Humanoid.Died:Once(function()
        self:Died(player)
    end)

    -- teleport player to spawn
    local Spawns = workspace:FindFirstChild("Spawns")
    local spawnLoc = Spawns and Spawns:FindFirstChild("Default")
    spawnLoc = spawnLoc or workspace.SpawnLocation

    character.PrimaryPart.Anchored = true
    character:SetPrimaryPartCFrame(spawnLoc.CFrame + Vector3.new(0,2,0))
    character.PrimaryPart.Anchored = false

    -- give player knife
    Ability.Add(player, "Dash")
    Ability.Add(player, "LongFlash")
    Weapon.Add(player, "AK47")
    Weapon.Add(player, "Glock17")
end


-- Player Died Function
function G1v1:Died(player)
    self.ended:Fire("Died", self:_getOtherPlayer(player), player)
end


--[[
    1v1 Gamemode Functions
]]


-- Starts round and specified RoundNumber
-- @return ended: BindableEvent - fires when ended
function G1v1:RoundStart(round: number)

    if self.ended then self.ended:Destroy() end
    self.ended = Instance.new("BindableEvent")
    
    -- disable any running connections
    self:_disconnectHotConns()

    -- custom player died event
    --table.insert(self.roundHotConnections, )

    -- timer
    local endt = tick() + self.roundLength
    local cte = self.roundLength -- exact time
    local currentTime = self.roundLength -- seconds
    local last = currentTime
    table.insert(self.roundHotConnections, RunService.Heartbeat:Connect(function()
        if endt and tick() >= endt then self.ended:Fire("Timer") endt = nil return end
        if not endt then return end
        cte = endt - tick()
        currentTime = math.floor(cte)
        if currentTime < last then -- seconds update
            print(currentTime)
        end
        last = currentTime
    end))

    -- spawn players
    for i, v in pairs(self.players) do
        self:SpawnPlayer(v)
    end

    return self.ended
end


-- Ends round, decides whether or not game is over
-- @return gameEnd: boolean
-- @return winner: player - if over
-- @return loser: player - if over
function G1v1:RoundEnd(condition: string, ...): boolean

    -- disable any running connections
    self:_disconnectHotConns()
    
    -- remove all weapons and abilities
    Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()

   -- player died shit
   if condition == "Died" then
        local winner, loser = ...
        
        -- update data
        self.roundPlayerData[winner.Name].kills += 1
        self.roundPlayerData[winner.Name].roundWins += 1
        self.roundPlayerData[loser.Name].deaths += 1
        --todo: damage

        -- decide game end
        if self.roundPlayerData[winner.Name].roundWins >= self.roundsToWin then
            return true, winner, loser
        end

        return false
   end

   -- ran out timer shit
    if condition == "Timer" then
        local r = math.round(math.random(100, 200)/100)
        local winner = self.players[r]
        local loser = self:_getOtherPlayer(winner)
        self.roundPlayerData[winner.Name].roundWins += 1

        -- decide game end
        if self.roundPlayerData[winner.Name].roundWins >= self.roundsToWin then
            return true, winner, loser
        end
    end
    return false
end


-- Ends game under specified condition
-- @return void
function G1v1:GameEnd(condition: string, ...)
    
end


-- PlayerDied round end event func
function G1v1:_roundEndPlayerDied(winner, loser)
    
end


-- util

function G1v1:_disconnectHotConns()
    for i, v in pairs(self.roundHotConnections) do
        v:Disconnect()
        v = nil
    end
end

function G1v1:_getOtherPlayer(player)
    for i, v in pairs(self.players) do
        if v ~= player then
            print(v.Name)
            return v
        end
    end
    return player
end

return G1v1