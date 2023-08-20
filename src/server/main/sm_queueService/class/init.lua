local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local DataStore = game:GetService("DataStoreService")

local classLoc = game:GetService("ServerScriptService"):WaitForChild("main").sm_queueService.class
local gameFoundGui = classLoc:WaitForChild("GameFoundGui")

local class = {
    options = {partySize = 2, maxPartySize = 0, checkInterval = 5},
    status = "running"
}
class.__index = class

function class.new(className: string, service)
    local self = setmetatable({}, class)
    self.connections = {}
    self.playeridstore = {} -- most recently receieved :GetStoredAsync which is usernames
    self.playerstorequeue = {} -- queue'd to add to store
    self.datastore = DataStore:GetOrderedDataStore(className .. "_Queue")
    self.service = service

    -- if we can't find the className, we just use the base class
    if className and classLoc:FindFirstChild(className) then
        for i, v in pairs(require(classLoc[className])) do
            self[i] = v
        end
    end

    -- custom easy access, low profile signal fired on interval
    self.signal = {
        IsConnected = false,
        _Callback = false,
        _Boolean = false,
        _Args = false,
        _IsOnce = false,

        _Connection = RunService.Heartbeat:Connect(function()
            if self.signal.IsConnected then
                if self.signal._Boolean and self.signal._Args and self.signal._Callback then
                    self.signal._Boolean = false

                    self.signal._Callback(table.unpack(self.signal._Args))
                    self.signal._Args = false

                    if self.signal._IsOnce then
                        self.signal._IsOnce = false
                        self.signal.IsConnected = false
                        self.signal._Callback = false
                    end 
                end
            end
        end),

        Connect = function(callback)
            if self.signal.IsConnected then
                warn("There is already a function connected to this signal... did you mean to do that?")
            end
            self.signal._Callback = callback
            self.signal.IsConnected = true
        end,

        Disconnect = function()
            self.signal._Callback = nil
            self.signal.IsConnected = false
        end,

        Fire = function(...)
            --if not self.signal.IsConnected then warn("Signal isn't connected") return end
            if not self.signal.IsConnected then return end
            self.signal._Args = table.pack(...)
            self.signal._Boolean = true
        end,

        Once = function(callback)
            if self.signal.IsConnected then
                warn("There is already a function connected to this signal... did you mean to do that?")
            end
            self.signal._Callback = callback
            self.signal._IsOnce = true
            self.signal.IsConnected = true
        end
    }

    self:UpdatePlayerTable()
    self:Connect()
    return self
end

-- Request a player be added to the queue
function class:RequestPlayerAdd(player: Player)
    local added = false

    -- local
    self.playerstorequeue[player.Name] = player
    print('Player added to queue locally!')

    -- global registration
    self.signal.Once(function()
        added = true
        print('Player added to queue globally!')
    end)

    -- 10 second timeout
    local _t = tick() + 10
    repeat task.wait() until added or tick() >= _t

    if not added then warn("Could not add player to global queue!") end
    return added
end

-- Request a player be removed from the queue
function class:RequestPlayerRemove(player: Player)
    if self.playerstorequeue[player.Name] then
        self.playerstorequeue[player.Name] = nil
        print('Player removed from both queues!')
        return true
    end

    local success = pcall(function()
        self.datastore:RemoveAsync(player.Name)
    end)

    if success then
        for i, v in pairs(self.playeridstore) do
            if v.key == player.Name then self.playeridstore[i] = nil end
        end
        print('Player removed from both queues!')
    end

    return success
end

-- Update local table from store
function class:UpdatePlayerTable()
    self.playeridstore = self.datastore:GetSortedAsync(true, 100):GetCurrentPage()
end

-- Adds any new players to datastore
function class:PlayerTableMerge()
    for i, v in pairs(self.playerstorequeue) do
        local alreadyinq = false
        for _, inq in pairs(self.playeridstore) do if inq.key == v.Name then warn("Player already in queue!") alreadyinq = true break end end -- check if player is in queue
        if alreadyinq then self.playerstorequeue[i] = nil continue end

        local success = pcall(function()
            self.datastore:SetAsync(v.Name, #self.playeridstore + 1)
        end)
        
        if success then
            self.playerstorequeue[i] = nil
        else
            warn("Could not add player to global queue")
        end
    end

    self:UpdatePlayerTable()
end

-- Checks for players. If full, it will send the players to a lobby.
-- Fires every 5 seconds
function class:PlayerCheck()
    if #self.playeridstore >= self.options.partySize then

        -- get the players
        local _party = self:GetTopPlayers(self.options.partySize)

        -- let them know they found a match
        task.spawn(function()
            for i, v in pairs(_party) do
                gameFoundGui:Clone().Parent = v.PlayerGui
            end
        end)

        -- remove players from queue
        self:RemoveParty(_party)

        -- send players to place
        self:SendPartyToPlace(_party)

    end
end

-- Get the earliest queueing players
function class:GetTopPlayers(total: number)

    -- at first, _party will be a table array, values = {playerName, queueRank}
    local _party = {}
    local _totalpartysize = 0

    -- first, we'll sort the players in the queue currently
    for index, array in pairs(self.playeridstore) do
        _totalpartysize += 1

        local ni = #_party
        for i, v in pairs(_party) do -- sort
            if i > v[2] then ni = i-1 end
        end

        _party[ni] = {Players[array.key], array.value} -- {Player, QueueSpot}
    end

    -- let's check if there is a total, or max party size set
    -- if not, we will set the total to the total party size
    if not total or total == 0 then
        total = _totalpartysize
    end

    -- this shouldn't happen hopefully
    if total == 0 then warn("Couldn't get total party size") total = 1 end

    -- now we get the top [total: number] of players,
    -- and put them in a table array
    local _top = {}
    for i = math.min(total, #_party), 0, -1 do
        table.insert(_top, _party[i][1])
    end

    -- i think this will help with mem
    _party = nil

    return _top
end

-- Remove a group of players from the queue
function class:RemoveParty(party: table) -- party: PlayerTable
    for i, v in pairs(party) do
        self.service:RemovePlayer(v)
        --self:RequestPlayerRemove(v)
    end
end

-- Connect the queue loop
function class:Connect()
    self.nxt = tick()
    self.connections.queueheartbeat = RunService.Heartbeat:Connect(function(dt)
        if tick() < self.nxt then return end
        self.nxt = tick() + self.options.checkInterval

        self:PlayerTableMerge()
        task.wait()

        self:PlayerCheck()

        self.signal.Fire()
    end)
end

-- Disconnect the queue loop
function class:Disconnect()
    self.connections.queueheartbeat:Disconnect()
    self.connections.signal:Disconnect()
end

function class:SendPartyToPlace()
end

-- [[ Extra ]]

--[[function class:ConvertIDsToPlayers(intable: table): table -- in: string table, out: player table
    local _p = {}
    local _ps = Players:GetPlayers()
    for i, v in pairs(intable) do
        table.insert(_p, _ps[v])
    end
    return _p
end]]

--[[function class:IsPlayerInQueue(player)
    if self.playerstorequeue[player.Name] then return true end
    self.playeridstore = self.playeridstore :: OrderedDataStore
    local q = self.playeridstore:GetSortedAsync(true, 100)
end]]

return class