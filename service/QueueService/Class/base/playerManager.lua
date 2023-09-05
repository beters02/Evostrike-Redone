--[[
    - PlayerManager is a class that will be created with and bound to a Queue Class.

        - It is an interface for the "store" module, adding and extra layer of safety via tick timeout,
        and some extra queue utility functions to make the management of players in the Queue more organized.


    - Note:

        - The only player functions that will not be kept here are ProcessPlayers and SendPlayers,
        those functions are instead apart of the Queue Class. (check Class/base)
]]

local Debris = game:GetService("Debris")
local QueueService = game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("QueueService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Types = require(QueueService.Types)
local ServicePlayerData = require(QueueService.ServicePlayerData)

local playerManager = {}
playerManager.__index = playerManager

--[[
]]
function playerManager.new(parentClass)
    local self = setmetatable({}, playerManager)
    self.__types = parentClass.__types
    self._parentClass = parentClass
    self._process = self._parentClass.storeModule.process -- easily access DataProcess
    self._storeModule = self._parentClass.storeModule
    print(self._process)
    print(self._storeModule)

    -- init manager var mutables
    self.var = {}

    self._waitingPlayers = {} -- players waiting to be added to queue
    self._cachedPlayers = {} -- cached version of players in datastore queue

    -- init manager configuration (var const)
    self:Init()
    return self
end

--[[
    Initialize the playerManager, which will initialize:
        - Stored Players
        - Validity of Stored Players
        - Stored Connections and Variables
]]
function playerManager:Init()

    -- initialize cache.
    -- call :Get() from the store module.
    self:UpdateCached()
    print(self._cachedPlayers)

    -- Validate
    self:ValidatePlayersInQueue()

end

--[[ Add a player to the queue ]]
function playerManager:Add(playerName: string)
    
    -- if player is in queue we dont need to add
    if self:IsPlayerInQueue(playerName) then
        return false, "Player already in queue!"
    end

    -- TODO:
    -- check if player is being processed on another server

    --TODO:
    -- set player processing var in ServicePlayerData

    -- init queue playerdata
    local qpd: Types.QueuePlayerData
    qpd = {
        Name = playerName,
        Slot = 1000, -- Temporarily set slot to 1000 while processing
        Objects = {Added = Instance.new("BindableEvent", game:GetService("ReplicatedStorage").temp)}
    }

    -- first we add locally
    self._waitingPlayers[playerName] = qpd

    print('Adding Local!')

    -- now we wait for the player to be added globally via playerManager:MergeWaiting()
    local added = false
    local timeout = tick() + 5
    local connection = qpd.Objects.Added.Event:Once(function()
        added = true
    end)

    repeat task.wait() until added or tick() >= timeout

    if not added then
        --todo: player not added globally callback
        qpd.Objects.Added:Destroy()
        connection:Disconnect()
        return false, "Could not add to DataStore. Try again soon."
    end

    ServicePlayerData[playerName].InQueue = self._parentClass.Name

    -- finished!
    qpd.Objects.Added:Destroy()
    return true
end

-- [[ Remove a player from the queue ]]
function playerManager:Remove(playerName: string)
    
    local inQueue, inLocation = self:IsPlayerInQueue(playerName)
    if not inQueue then
        return false, "Player not in queue!"
    end

    -- nice and easy
    if inLocation == "waiting" then
        self._waitingPlayers[playerName] = nil
        return true
    end

    -- not so nice or easy
    -- attempt to remove from datastore
    local success, err = self._storeModule:Remove(playerName)
    if not success then
        --todo: player cant be removed callback, store in localplayerdata that they should not be added to queues.
        return false, err
    end

    -- remove from cached table if neccessary
    for i, v in pairs(self._cachedPlayers) do -- nice and slow aswell
        if v.Name == playerName then
            table.remove(self._cachedPlayers, i)
        end
    end

    ServicePlayerData[playerName].InQueue = false

    -- done!
    return true
end

--[[
    Check if player is in queue
    Will return queueLocation (waitingPlayers, cachedPlayers)

    You know this is actually kind of really slow now that i think about it, whatevs.
    will add a CurrentQueue key to QueueService PlayerData

    @return inQueue: boolean, queueLocation: table?
]]
function playerManager:IsPlayerInQueue(playerName: string)
    for i, v in pairs(self._waitingPlayers) do
        if v.Name == playerName then
            return true, "waiting"
        end
    end
    for i, v in pairs(self._cachedPlayers) do
        if v.Name == playerName then
            return true, "cached"
        end
    end
    return false
end

-- [[ Get all the players in the cached queue ]]
function playerManager:GetPlayers()
    return self._cachedPlayers
end

-- [[ Remove a group of players from the queue ]]
-- @return removedAllPlayers: boolean, playersNotRemoved: table<Player>?
function playerManager:RemovePlayers(players) -- players: table<QueuePlayerData>
    local success, err

    local couldntRemove = {}
    for i, v in pairs(players) do
        success, err = pcall(function()
            self:Remove(v.Name)
        end)
        if not success then
            table.insert(couldntRemove, v)
            continue
        end
    end

    if #couldntRemove > 0 then
        return false, couldntRemove
    end

    return true
end

-- [[ Check if player is on this server or another one ]]
function playerManager:IsPlayerLocal(playerName: string)
    return Players:FindFirstChild(playerName) and true or false
end

-- [[ == Lower level manager functions == ]] --

--[[ Validate authenticity of players in the cached queue. (Check if real/online) ]]
function playerManager:ValidatePlayersInQueue()
    return _validatePlayersInTable(self, self._cachedPlayers)
end

-- Incase we need to validate elsewhere
function _validatePlayersInTable(self, tab)
    local success, err

    for i, v in pairs(tab) do

        if Players:FindFirstChild(v.Name) then
            continue
        end

        -- attempt to get userID and find player in another server
        success, err = pcall(function()
            TeleportService:GetPlayerPlaceInstanceAsync(Players:GetUserIdFromNameAsync(v.Name))
        end)

        if not success then
            warn("Player " .. v.Name .. " not verified: " .. tostring(err))

            -- attempt to remove player from queue
            task.spawn(function()
                self:Remove(v.Name)
            end)

            tab[i] = nil
            continue
        end

        -- done! player verified
    end
end

--[[ Attempt to add all of the currently waiting players into the queue ]]
function playerManager:MergeWaiting()
    local success, err

    for i, v in pairs(self._waitingPlayers) do

        success, err = pcall(function()
            self._storeModule:Add(v.Name, #self._storeModule + 1)
            table.insert(self._storeModule, v)
            self._storeModule:Save()
        end)

        if not success then
            warn("Player could not be added to global queue. Removing")
            --todo: fire Result false
        end

        v.Objects.Added:Fire()
    end

    self._waitingPlayers = {}
end

function playerManager:UpdateCached()
    self._cachedPlayers = self._storeModule:Get()
    -- convert data key, value to QueuePlayerData Name Slot
    for i, v in pairs(self._cachedPlayers) do
        self._cachedPlayers[i] = {
            Name = v.key,
            Slot = v.value
        }:: Types.QueuePlayerData
    end
end

--[[ TODO: Combines the current DataStore with the cache'd queuePlayerStore ]]
function playerManager:CombineStore()
    self._cachedPlayers = self._storeModule:Get()
end

-- [[ Notify a group of online players that a match has been found ]]
function playerManager:NotifyGameFound(players)
    local _c
    for i, v in pairs(players) do
        _c = self._parentClass.GameFoundGui:Clone()
        _c.Parent = v.PlayerGui
        Debris:AddItem(_c, 30)
    end
end

return playerManager