--[[
    Base Class will automatically define BaseClassLocation
    Base Class will automatically initialize (modules) upon first start
]]

--[[
    To Do:

    Connect MessagingService:SubscribeAsync("RemovePlayer"), "RemovePlayerResult", "GetPlayerDataResult"
]]

local DataStore = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local VRService = game:GetService("VRService")
local PlayerData = require(Framework.sm_serverPlayerData.Location)

local base = {}
base.__index = base
base.Name = "Base"

base._baseLocation = game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("QueueService").QueueManager.QueueClasses.base
base._var = {
    isInit = false,
    isProcessing = false,
    nextProcessTime = tick(),
    connections = {}
}

base.config = {
    updateInterval = 5,
    minParty = 2,
    maxParty = 8
}

base.datastore = false
base.stored = {
    playerIDdata = {},
    playerAddingQueue = {},
    playerRemovingQueue = {}
}

export type TeleportInfo = {
    PlaceID: number,
    JobID: number|nil,
    Gamemode: string|nil,
    PrivateCode: number|nil
}

function base.new(class: string)

    -- search for class
    local _c = base._baseLocation.Parent:FindFirstChild(class)
    if not _c then return false, "Couldn't find class " .. tostring(class) end
    _c = require(_c)

    -- meta class iheritence
    _c = setmetatable(_c, base)

    -- data modules
    _c.datastore = DataStore:GetOrderedDataStore(_c.Name .. "_Queue")

    return _c
end

--#region Add Player

function base:AddPlayer(player: Player)
    local playerdata = PlayerData.GetPlayerData(player)

    -- Check if player is already being added/removed from a queue
    if playerdata.states.isQueueAdding or playerdata.states.isQueueRemoving then
        warn("Player is already being added or removed from queue.")
        return false
    end

    print("Adding player " .. player.Name .. " to queue!")

    -- Quickly set isQueueAdding variable with pcalls
    local success, err = self:SetPlayerDataIsQueueVar("adding", player, playerdata, true)
    if not success then warn("Cannot add player to queue, cant set IsVar") return false end

    -- Check if player is in queue
    if self:IsPlayerInQueue(player) then
        warn("Player already in queue!")
        success = self:SetPlayerDataIsQueueVar("adding", player, playerdata, false)
        if not success then self:SetPlayerDataIsQueueVar("adding", player, playerdata, false) end -- retry once
        return true
    end

    -- Add Player To playerAddingQueue
    base.stored.playerAddingQueue[player.Name] = {player, Instance.new("BindableEvent", game:GetService("ReplicatedStorage").temp)}

    -- Wait for player to be added to GlobalQueue (Check _AddPlayerGlobal)
    success, err = base.stored.playerAddingQueue[player.Name][2].Event:Wait()
    if success then
        print(player.Name .. " added to " .. self.Name .. " queue globally!")
    else
        warn("Could not add player globally, player will be removed from local queue. Error: " .. tostring(err))
    end

    base.stored.playerAddingQueue[player.Name][2]:Destroy()

    self:SetPlayerDataIsQueueVar("adding", player, playerdata, false)
    return success
end

function _AddPlayerGlobal(self, player: Player) -- Called in Update

    local success, err = pcall(function()
        local index = #self.stored.playerIDdata + 1 -- This is the player's position in the queue.
        self.datastore:SetAsync(player.Name, index)
        self.stored.playerIDdata[index] = {key = player.Name, value = index}
    end)

    if not success then
        return false, err
    end

    return true
end

function _MergeAddQueue(self)
    for i, v in pairs(self.stored.playerAddingQueue) do
        local success, err = _AddPlayerGlobal(self, v[1])
        v[2]:Fire(success, err)
    end

    task.wait()
    self.stored.playerAddingQueue = {}
end

--#endregion

--#region Remove Player

function base:RemovePlayer(player: Player)
    local playerdata = PlayerData.GetPlayerData(player)

    -- Check if player is already being added/removed from a queue
    print(playerdata.states)
    if playerdata.states.isQueueAdding or playerdata.states.isQueueRemoving then
        warn("Player is already being added or removed from queue.")
        return false
    end

    print("Removing player " .. player.Name .. " from queue!")

    -- Quickly set isQueueAdding variable with pcalls
    local success, err = self:SetPlayerDataIsQueueVar("removing", player, playerdata, true)
    if not success then warn("Cannot add player to queue, cant set IsVar") return false end

    -- Check if player is in queue
    local isInQueue, queueLoc = self:IsPlayerInQueue(player)
    if not isInQueue then
        warn("Player not in queue!")
        success = self:SetPlayerDataIsQueueVar("removing", player, playerdata, false)
        if not success then self:SetPlayerDataIsQueueVar("removing", player, playerdata, false) end -- retry once
        return false, "Player not in queue"
    end

    -- If player is in local queue, this is nice and easy
    if queueLoc == "local" then
        self.stored.playerAddingQueue[player.Name] = nil
        success = self:SetPlayerDataIsQueueVar("removing", player, playerdata, false)
        if not success then self:SetPlayerDataIsQueueVar("removing", player, playerdata, false) end -- retry once
        return true
    end

    -- Otherwise, attempt to remove from global store (Will automatically retry if failed)
    return _RemovePlayerGlobal(self, player, playerdata, queueLoc) -- queueLoc will be playerIDstore index
end

function base:RemovePlayerOtherServer(playerName: string) -- Returns Thread
    local _finished = false
    return task.spawn(function()
        local _conn
        _conn = MessagingService:SubscribeAsync("RemovePlayerResult", function(data)
            if data.Name ~= playerName then return end
            if not data.Result then
                warn("Couldn't remove player from other server: " .. tostring(data.Error))
            else
                print("Player " .. playerName .. " removed from other server!")
                self.stored.playerIDdata[data.Result] = nil -- Remove other player from playerIDdata
            end
            _finished = true
            _conn:Disconnect()
        end)

        MessagingService:PublishAsync("RemovePlayer", self.Name, playerName)

        repeat task.wait() until _finished
    end)
end

function _RemovePlayerGlobal(self, player, playerdata, index)

    local success, err = pcall(function()
        self.datastore:RemoveAsync(player.Name)
        table.remove(self.stored.playerIDdata, index)
    end)

    if not success then
        -- Set player's isQueueDisabled to be true while we can't remove global.
        self:SetPlayerDataIsQueueVar("disabled", player, playerdata, true)

        -- Add to playerRemovingQueue to be tried again.
        if not self.stored.playerRemovingQueue[player.Name] then
            self.stored.playerRemovingQueue[player.Name] = player
        end

        warn("Could not remove player globally... " .. tostring(err))

        return false, err
    end

    self:SetPlayerDataIsQueueVar("disabled", player, playerdata, false)
    self:SetPlayerDataIsQueueVar("removing", player, playerdata, false)

    if self.stored.playerRemovingQueue[player.Name] then
        self.stored.playerRemovingQueue[player.Name] = nil
    end

    print('Player removed from queue successfully!')

    return true
end

function _RemovePlayerGlobalByName(self, player, index)

    local success, err = pcall(function()
        self.datastore:SetAsync(player.Name, nil)
        table.remove(self.stored.playerIDdata, index)
    end)

    if not success then
        -- Add to playerRemovingQueue to be tried again.
        if not self.stored.playerRemovingQueue[player.Name] then
            self.stored.playerRemovingQueue[player.Name] = {player, index}
        end
        return false
    end

    return true
end

function _CheckRemoveQueue(self)
    for i, v in pairs(self.stored.playerRemovingQueue) do -- i = playerName, v = player
        if type(v) == "table" then
            _RemovePlayerGlobalByName(self, v[1], v[2])
            continue
        end

        self:RemovePlayer(v)
    end
end

--#endregion

--#region Queue Player Management

function base:IsPlayerInQueue(player)
    if type(player) == "string" then player = {Name = player} end

    local _b = false
    local _loc = ""

    -- first check local
    for i, v in pairs(self.stored.playerAddingQueue) do
        if i == player.Name then _b = true _loc = "local" break end
    end

    -- then check global (local cache of global)
    if not _b then
        for i, v in pairs(self.stored.playerIDdata) do
            if v.key == player.Name then _b = true _loc = i break end
        end
    end
    
    return _b, _loc
end

function base:SetPlayerDataIsQueueVar(action: string, player, playerdata, bool)
    local stateKey
    if action == "adding" then
        stateKey = "isQueueAdding"
    elseif action == "removing" then
        stateKey = "isQueueRemoving"
    elseif action == "disabled" then
        stateKey = "isQueueDisabled"
    end

    playerdata[stateKey] = bool

    -- Set PlayerData
    local success, err = pcall(function()
        PlayerData.SetPlayerData(player, playerdata)
    end)
    if not success then warn("Could not " .. stateKey .. " player to queue, Cant set PlayerData. Error: " .. tostring(err)) return false end

    -- Save PlayerData
    success, err = pcall(function()
        PlayerData.SavePlayerData(player)
    end)

    if not success then
        warn("Could not " .. stateKey .. " player to queue, Cant save PlayerData. Error: " .. tostring(err))
        playerdata.states[stateKey] = not bool
        PlayerData.SetPlayerData(player, playerdata)
        return false
    end

    return true
end

-- @return
function _GetTopPlayersInQueue(self, verificationData)
    if not verificationData then error("GetTopPlayersInQueue requires verification data.") end
    if #self.stored.playerIDdata == 0 then return {} end
    local total = self.config.maxParty

    -- store finished var for once all threads have completed
    local _finishedGotTop = false
    local _finishedIndex = #self.stored.playerIDdata
    local _timeout = tick() + 5
    
    -- at first, _party will be a table array, values = {playerName, queueRank}
    local _party = {}
    local _totalpartysize = 0

    -- first, we'll sort the players in the queue currently
    task.spawn(function()
        for index, array in pairs(self.stored.playerIDdata) do

            -- now we have to check if player can actually queue
            -- if player is not on this server, we check if theyre on other server
            if not verificationData[array.key] then warn("Player " .. array.key .. " not registered in queue! No verification data stored.") continue end
    
            local playerdata
            if verificationData[array.key].IsLocal then
                playerdata = PlayerData.GetPlayerData(verificationData[array.key].IsLocal)
            else
                local _tick = tick() + 2 -- 2 second timeout
                local _conn
                _conn = MessagingService:SubscribeAsync("GetPlayerDataResult", function(data)
                    if data.Name ~= array.key then return end
                    playerdata = data.Result
                end)
                MessagingService:PublishAsync("GetPlayerData", array.key)
                repeat task.wait() until playerdata or tick() >= _tick
                _conn:Disconnect()
            end

            if not playerdata then if index == _finishedIndex then _finishedGotTop = true end continue end
    
            _totalpartysize += 1
    
            local ni = #_party
            for i, v in pairs(_party) do -- sort
                if i > v[2] then ni = i-1 end
            end
    
            _party[ni] = array -- {key = PlayerName, value = QueueSpot}
    
            if index == _finishedIndex then
                _finishedGotTop = true
            end
        end
    end)

    -- wait for threads to complete here
    repeat task.wait() until _finishedGotTop or tick() >= _timeout

    if not _finishedGotTop then return {} end

    -- let's check if there is a total, or max, party size set
    -- if not, we will set the total to the total party size
    if not total or total == 0 then
        total = _totalpartysize
    end

    -- this shouldn't happen hopefully
    if total == 0 then warn("Couldn't get total party size") return {} end

    -- now we get the top [total: number] of players,
    -- and put them in a table array
    if not total or total == 0 then total = #_party else total = math.min(total, #_party) end
    local _top = {}
    for i = total, 0, -1 do
        table.insert(_top, _party[i][1])
    end

    -- i think this will help with mem
    _party = nil

    return _top
end

function _UpdatedStoredPlayersFromDataStore(self)
    self.stored.playerIDdata = self.datastore:GetSortedAsync(true, 100):GetCurrentPage()
end

function _VerifyStoredPlayers(self)
    local verificationData = {}

    for index, data in pairs(self.stored.playerIDdata) do
        local success, err

        -- [[ Player UserID Verification ]]
        local userid
        success, err = pcall(function()
            userid = Players:GetUserIdFromNameAsync(data.key)
        end)

        if not success then
            _RemovePlayerGlobalByName(self, data.key, data.value)
            warn("Could not get UserID from PlayerName " .. tostring(data.key) .. ". Error: " .. tostring(err))
            continue
        end

        --[[ Player Online Verification ]]
        local localPlayer = Players:FindFirstChild(data.key)

        -- Check if player is on another server if necessary
        if not localPlayer then
            
            success, err = pcall(function()
                TeleportService:GetPlayerPlaceInstanceAsync(userid)
            end)
    
            if not success then
                _RemovePlayerGlobalByName(self, data.key, data.value)
                warn("Could not find Player online " .. tostring(data.key) .. ". Error: " .. tostring(err))
                continue
            end
        end

        verificationData[data.key] = {Name = data.key, Index = data.value, UserID = userid, IsLocal = localPlayer and localPlayer or false}
    end

    return verificationData
end

function _SeperateInAndNotInServerPlayers(party: table)
    local sep = {InPlayers = {}, OutPlayers = {}}
    for i, v in pairs(party) do
        if Players:FindFirstChild(v.key) then
            table.insert(sep.InPlayers, v.key)
        else
            table.insert(sep.OutPlayers, v.key)
        end
    end
    return sep
end

--#endregion

--#region Main

function base:Start()
    self:Connect()
end

function base:Stop()
    self:Stop()
end

function base:Connect()
    self._var.connections.UpdateLoop = RunService.Heartbeat:Connect(function() self:UpdateLoop() end)
    self._var.connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        if self:IsPlayerInQueue(player) then
            self:RemovePlayer(player)
        end
    end)
end

function base:Disconnect()
    for i, v in pairs(self._var.connections) do
        v:Disconnect()
    end
    self._var.connections = {}
end

function base:Update() -- Called Every [interval] Seconds

    -- update players from current store
    _UpdatedStoredPlayersFromDataStore(self)
    task.wait()

    -- merge stored queue players
    _MergeAddQueue(self)
    task.wait()

    -- fulfill remove requests
    _CheckRemoveQueue(self)
    task.wait()

    -- verify stored queue players are real and online
    local verificationData = _VerifyStoredPlayers(self)
    task.wait()

    -- process
    self:ProcessQueue(verificationData)
    task.wait()

end

function base:UpdateLoop() -- Called Every Frame
    if tick() >= self._var.nextProcessTime then
        self._var.nextProcessTime = tick() + self.config.updateInterval
        self:Update()
    end
end

function base:ProcessQueue(verificationData)
    if self._var.isProcessing then return end
    
    if #self.stored.playerIDdata >= self.config.minParty then
        self._var.isProcessing = true

        -- get top players & convert to in and out
        local top = _GetTopPlayersInQueue(self, verificationData)
        if not top or #top == 0 then
            warn("Could not get top players when there were enough players in queue!")
            self._var.isProcessing = false
            return
        end

        local sep = _SeperateInAndNotInServerPlayers(top)
        if not sep then
            warn("Could not seperate top table... this is stupid")
            self._var.isProcessing = false
            return
        end

        -- remove these players from queue
        for i, v in pairs(top) do
            if Players:FindFirstChild(v.key) then
                self:RemovePlayer(Players[v.key])
            else
                self:RemovePlayerOtherServer(v.key)
            end
        end

        -- prepare teleport information
        local teleportInfo: TeleportInfo
        local openServer = self:CheckForOpenServers(top)

        if openServer then
            teleportInfo = openServer
        else
            -- create private server
            local _id = self:GetRandomMap()
            teleportInfo = {
                PlaceID = _id,
                PrivateCode = TeleportService:ReserveServer(_id),
                Gamemode = self.Name
            }:: TeleportInfo
        end

        -- first teleport out players and verify that they have teleported
        for i, v in pairs(sep.OutPlayers) do
            if Players:FindFirstChild(v.key) then
                warn("Player is an InPlayer! Not an OutPlayer. How'd that happen?")
                table.insert(sep.InPlayers, v)
                continue
            end

            -- private server
            if teleportInfo.PrivateCode then
                MessagingService:PublishAsync("TeleportPlayer", "private", teleportInfo)
            else
            -- public server
                MessagingService:PublishAsync("TeleportPlayer", "public", {ServerInstanceId = teleportInfo.JobID}:: TeleportOptions)
            end
        end

        -- private server
        if teleportInfo.PrivateCode then
            TeleportService:TeleportToPrivateServer(teleportInfo.PlaceID, teleportInfo.PrivateCode, sep.InPlayers, false, {RequestedGamemode = teleportInfo.Gamemode})
        else
        -- public server
            TeleportService:TeleportAsync(teleportInfo.PlaceID, sep.InPlayers, {ServerInstanceId = teleportInfo.JobID}:: TeleportOptions)
        end

        self._var.isProcessing = false
    end
end

function base:CheckForOpenServers(top) -- top = TopPlayers
    local teleportInfo = false
    local _len = tick() + 1.5
    local _serverInfos = {}
    local _conn
    _conn = MessagingService:SubscribeAsync("GetServerInfoResult", function(data)
        table.insert(_serverInfos, data)
    end)

    MessagingService:PublishAsync("GetServerInfo")

    repeat task.wait() until tick() >= _len

    if #_serverInfos > 0 then
        for i, v in pairs(_serverInfos) do
            if v.jobid == game.JobId then continue end
            if v.gamemode == self.Name and v.totalPlayers + #top <= self.config.maxParty then
                teleportInfo = {
                    PlaceID = v.placeid,
                    JobID = v.jobid
                }:: TeleportInfo
                break
            end
        end
    end

    return teleportInfo
end

function base:GetRandomMap()
    local _map = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))
    return _map[math.random(1,#_map)]
end

--#endregion

return base