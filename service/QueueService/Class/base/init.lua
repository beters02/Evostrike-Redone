--[[
    QueueClass Base.

    TODO:   TeleportPlayers MessagingService
            Notify players when they have found a match
            Add queue to retry once it's been processed if there is less than max players
]]

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local QueueService = game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("QueueService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ServicePlayerData = require(QueueService.ServicePlayerData)
local Types = require(QueueService.Types)
local MapIDs = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))

local base = {}
base.__index = base
base._baseLocation = QueueService.Class.base

--[[ Configuration ]]
base.Name = "Base"
base.QueueInterval = 5
base.MaxParty = 8
base.MinParty = 2
base.GameFoundGui = base._baseLocation.GameFoundGui

--[[ Class ]]

function base.new(class: string)

    -- search for class
    local _c = base._baseLocation.Parent:FindFirstChild(class)
    if not _c then return false, "Couldn't find class " .. tostring(class) end
    _c = require(_c)

    -- meta class iheritence
    _c = setmetatable(_c, base)

    -- initialize store module
    _c.storeModule = require(base._baseLocation.store).new(class)
    _c.storeModule:Init()

    -- init process module
    _c.process = _c.storeModule.process

    -- init PlayerManager
    _c.playerManager = require(base._baseLocation.playerManager).new(_c)

    -- init var
    _c._connections = {}
    _c.Name = class

    -- grab queue datastore
    local success, err = pcall(function()
        _c.storeModule:Init()
    end)

    if not success then
        error(tostring(err))
        return false
    end

    return _c
end

function base:Update() -- Called every interval

    -- first we add the waiting players to the queue
    self.playerManager:MergeWaiting()
    task.wait(0.1)

    -- now we update the cached data value from datastore
    self.playerManager:UpdateCached()

    -- validate authenticity of queued players
    self.playerManager:ValidatePlayersInQueue()

    -- process players
    if self:CanProcess() then
        self:ProcessPlayers()
    end

end

function base:Connect()
    local _nxt = tick()
    self._connections.update = RunService.Heartbeat:Connect(function()
        if tick() >= _nxt then
            _nxt = tick() + self.QueueInterval
            self:Update()
        end
    end)
    self._connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        -- remove player from queue if necessary
        if ServicePlayerData[player.Name] and ServicePlayerData[player.Name].InQueue == self.Name then
            self.playerManager:Remove(player.Name)
        end
    end)
end

function base:Disconnect()
    self._connections.update:Disconnect()
end

--

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- Final stage when queue is ready to send players into a lobby
-- Done outside of playerManager since this function will want to be edited per Queue Class
function base:ProcessPlayers()
    local sorted = {} -- table<Slot>
    local sortedData = {} -- used to store PlayerDatas, set to nil after process
    local sending = {} -- table<QueuePlayerData>

    -- sort cached players in queue
    -- convert PlayerData into table<Slot>
    for _, v in pairs(self.playerManager._cachedPlayers) do
        sorted[v.Name] = v.Slot
        sortedData[v.Name] = v
    end

    -- sort using iterator function
    -- replace sorted Slot with PlayerData
    local count = 0
    for i, v in spairs(sorted, function(t,a,b) return t[b] > t[a] end) do
        count += 1
        sorted[count] = sortedData[i]
    end

    -- convert dictionary to table
    for i, v in pairs(sorted) do
        if type(i) == "string" then
            sorted[i] = nil
        end
    end

    -- memsave
    sortedData = nil
    count = nil

    -- queue up players to be sent
    for i, v in pairs(sorted) do

        -- if we have reached max size, send this current party.
        if #sending >= self.MaxParty then
            self:SendPlayers(sending)
            task.wait(0.1)
            sending = {}
            if #sorted - i < self.MinParty then
                -- party too small
                return
            end
        end

        -- insert playerdata to be sent
        table.insert(sending, v)
    end

    -- finished! send these bitches
    self:SendPlayers(sending)
end

-- Send players to place

function base:SendPlayers(players) -- players: table<QueuePlayerData>

    -- first we need to remove these players from the queue
    local removedAll, playersNotRemoved = self.playerManager:RemovePlayers(players)
    if not removedAll then
        warn("Couldnt remove all players from queue, no callback found")
    end

    -- now we will convert the PlayerData table into LocalPlayer's Players and other Player's PlayerNames
    local teleport = {_local = {}, _other = {}}
    for i, v in pairs(players) do

        -- check if player is local or server
        -- if local then we will insert the player into teleport._local
        if self.playerManager:IsPlayerLocal(v.Name) then
            table.insert(teleport._local, game:GetService("Players")[v.Name])
        else
            table.insert(teleport._other, v.Name)
        end

    end

    -- notify online players about match finding
    self.playerManager:NotifyGameFound(teleport._local)

    -- create the server
    local serverData = self:CreateServerData(teleport._local)

    -- Handle local players
    TeleportService:TeleportToPrivateServer(serverData.PlaceID, serverData.PrivateID, serverData.Players, "", {RequestedGamemode = serverData.Gamemode})

    -- Handle server players
    -- TODO: messaging service
    MessagingService:PublishAsync("TeleportPlayers", self._other)
    
end

--

function base:CreateServerData(players)
    local map = self:GetMap()

    local serverData: Types.ServerData
    serverData = {
        IsPrivate = true,
        PrivateID = TeleportService:ReserveServer(map),

        PlaceID = map,
        Gamemode = self.Name,
        Players = players
    }

    return serverData
end

function base:GetMap()
    return MapIDs.GetMapsInGamemode(self.Name)
end

--

function base:CanProcess()
    return #self.playerManager:GetPlayers() >= self.MinParty
end

return base