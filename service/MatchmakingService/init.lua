local CLOSED = false

local PLAYERSADDED = {}
local PLAYERSREMOVED = {}
local PLAYERSADDEDTHISWAVE = {}

local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")
local DatastoreService = game:GetService("DataStoreService")

local SkillDatastore = DatastoreService:GetDataStore("MATCHMAKINGSERVICE_SKILLS")

-- local Cache = require(script.Cache)
local OpenSkill = require(script.OpenSkill)
local Signal = require(script.Signal)

local MainMemory = MemoryStoreService:GetSortedMap("MATCHMAKINGSERVICE")
local JoinableGamesMemory = MemoryStoreService:GetSortedMap("MATCHMAKINGSERVICE_JOINABLE_GAMES")
local NonJoinableGamesMemory = MemoryStoreService:GetSortedMap("MATCHMAKINGSERVICE_NONJOINABLE_GAMES")
local MemoryQueue = MemoryStoreService:GetSortedMap("MATCHMAKINGSERVICE_QUEUE")
local TeleportDataMemory = MemoryStoreService:GetSortedMap("MATCHMAKINGSERVICE_TELEPORT_DATA")

-- GAME SERVER VARIABLES
local _gameData = nil 
local _gameId = nil

local MatchmakingService = {
  Singleton = nil;
  Version = "3.0.0-beta.3";
  Versions = {
    ["v1"] = 8470858629;
    ["v2"] = 8898097654;
    ["v3"] = 13533090734;
  };
}

MatchmakingService.__index = MatchmakingService

-- Useful table utilities
function first(haystack, num, skip)
  if haystack == nil then return nil end
  if skip == nil then skip = 1 end
  local toReturn = {}
  for i = skip, num + (skip - 1) do
    if i > #haystack then break end
    table.insert(toReturn, haystack[i])
  end
  return toReturn
end

function find(haystack, needle)
  if haystack == nil then return nil end
  for i, v in ipairs(haystack) do
    if needle(v) then
      return i
    end
  end
  return nil
end

function dictlen(dict)
  local counter = 0
  for _ in pairs(dict) do
    counter += 1
  end
  return counter
end

function any(haystack, cond)
  if haystack == nil or cond == nil then return false end
  for i, v in pairs(haystack) do
    if cond(v) then
      return true
    end
  end
  return false
end

function all(haystack, needles)
  if haystack == nil or needles == nil then return false end
  local hasNeedles = {}
  for i, v in ipairs(needles) do
    hasNeedles[v] = false
  end
  for i, v in ipairs(haystack) do
    if table.find(needles, v) ~= nil then
      hasNeedles[v] = true
    end
  end
  return not any(hasNeedles, function(x) return not x end)
end

function reduce(haystack, transform, default)
  local cur = default or 0
  for k, v in pairs(haystack) do
    cur = transform(cur, v, k, haystack)
  end
  return cur
end

function tableSelect(haystack, prop)
  if haystack == nil then return nil end
  local toReturn = {}
  for i, v in ipairs(haystack) do
    table.insert(toReturn, v[prop])
  end
  return toReturn
end

function append(tbl, tbl2)
  if tbl == nil or tbl2 == nil then
    return nil
  end
  for _, v in ipairs(tbl2) do
    table.insert(tbl, v)
  end
end

-- End table utilities

-- Useful utilities

-- Rounds a value to the nearest 10
function roundSkill(skill)
  return math.round(skill/10) * 10
end

function checkForParties(values)
  for i, v in ipairs(values) do
    if v[3] ~= nil and i + v[3] > #values then
      for j = #values, i, -1 do
        table.remove(values, j)
      end
      return false
    end
  end
  return true
end

function getFromMemory(m, k, retries)
  if retries == nil then retries = 3 end
  local success, response
  local count = 0
  while not success and count < retries do
    success, response = pcall(m.GetAsync, m, k)
    count += 1
    if not success then task.wait(3) end
  end
  if not success then warn(response) end
  return response
end

function updateQueue(map: string, ratingType, stringRoundedRating, role)
  local now = DateTime.now().UnixTimestampMillis
  local success, errorMessage

  if role == nil then
    role = "MMS_NO_ROLE"
  end

  success, errorMessage = pcall(function()
    MemoryQueue:UpdateAsync("QueuedMaps", function(old)
      if old == nil then 
        old = {map}
      else
        if find(old, function(v)
            return v == map
          end) then
          return old
        end
        table.insert(old, map)
      end
      return old
    end, 86400)
  end)

  if not success then
    print("Unable to update queued maps:")
    warn(errorMessage)
  end

  success, errorMessage = pcall(function()
    MemoryQueue:UpdateAsync(map.."__QueuedRatingTypes", function(old)
      if old == nil then 
        old = {}
        old[ratingType] = {{stringRoundedRating, now}}
      elseif old[ratingType] == nil then
        old[ratingType] = {{stringRoundedRating, now}}
      else
        if find(old[ratingType], function(v)
            return v[1] == stringRoundedRating
          end) then
          return old
        end
        table.insert(old[ratingType], {stringRoundedRating, now})
      end
      return old
    end, 86400)
  end)

  if not success then
    print("Unable to update queued rating types:")
    warn(errorMessage)
  end
end

-- End useful utilities


-- Private connections

-- End private connections

type Singleton = {
  AddGamePlace: (self: {}, name: string, placeId: number) -> ();
  SetMatchmakingInterval: (self: {}, newInterval: number) -> ();
  SetPlayerRange: (self: {}, map: string, newPlayerRange: NumberRange) -> ();
  SetIsGameServer: (self: {}, newValue: boolean, updateJoinableOnLeave: boolean) -> ();
  SetStartingMean: (self: {}, newStartingMean: number) -> ();
  SetStartingStandardDeviation: (self: {}, newStartingStandardDeviation: number) -> ();
  SetMaxPartySkillGap: (self: {}, newMaxGap: number) -> ();
  SetSecondsBetweenExpansion: (self: {}, newValue: number) -> ();
  SetFoundGameDelay: (self: {}, newValue: number) -> ();
  Clear: (self: {}) -> ();

  GetCurrentGameCode: (self: {}) -> (number?);
  GetGameData: (self: {}, code: string) -> ({any?}?);

  --GetUserDataId: (self: {}, player: number) -> ({any?}?);
  GetUserData: (self: {}, player: Player) -> ({any?}?);

  ToRatingNumber: (self:{}, openSkillObject: any) -> (number);
  --GetPlayerRatingId: (self: {}, player: number, ratingType: string) -> ({mu: number, sigma: number}?);
  GetPlayerRating: (self: {}, player: Player, ratingType: string) -> ({mu: number, sigma: number}?);
  --SetPlayerRatingId: (self: {}, player: number, ratingType: string, rating: {mu: number, sigma: number}) -> ();
  SetPlayerRating: (self: {}, player: Player, ratingType: string, rating: {mu: number, sigma: number}) -> ();

  --ClearPlayerInfoId: (self: {}, playerId: number) -> ();
  ClearPlayerInfo: (self: {}, player: Player) -> ();
  --SetPlayerInfoId: (self: {}, player: number, code: string, ratingType: string, party: {number}, map: string, teleportAfter: number) -> ();
  SetPlayerInfo: (self: {}, player: Player, code: string, ratingType: string, party: {number}, map: string, teleportAfter: number) -> ();
  --GetPlayerInfoId: (self: {}, player: number) -> (PlayerInfo);
  GetPlayerInfo: (self: {}, player: Player) -> (PlayerInfo);

  GetQueueCounts: (self:{}) ->({any}, number);

  GetAllRunningGames: (self:{}) ->({any});
  GetRunningGame: (self: {}, code: string) ->({any}?);

  GetQueue: (self:{}, map: string) -> ({[string]: {[any]: {any}}}?);
  --QueuePlayerId: (self: {}, player: number, ratingType: string, map: string) -> (boolean);	
  QueuePlayer: (self: {}, player: Player, ratingType: string, map: string) -> (boolean);	
  --QueuePartyId: (self: {}, players: {number}, ratingType: string, map: string) -> (boolean);
  QueueParty: (self: {}, players: {Player}, ratingType: string, map: string) -> (boolean);
  --GetPlayerPartyId: (self: {}, player: number) -> ({number}?);
  GetPlayerParty: (self: {}, player: Player) -> ({number}?);
  --RemovePlayerFromQueueId: (self: {}, player: number) -> (boolean?);
  RemovePlayerFromQueue: (self: {}, player: Player) -> (boolean?);
  --RemovePlayersFromQueueId: (self: {}, players: {number}) -> (boolean?);	
  RemovePlayersFromQueue: (self: {}, players: {Player}) -> (boolean?);	

  --AddPlayerToGameId: (self: {}, player: number, gameId: string, updateJoinable: boolean) -> (boolean?);	
  AddPlayerToGame: (self: {}, player: Player, gameId: string, updateJoinable: boolean) -> (boolean?);
  --AddPlayersToGameId: (self: {}, players: {number}, gameId: string, updateJoinable: boolean) -> (boolean?);
  AddPlayersToGame: (self: {}, players: {Player}, gameId: string, updateJoinable: boolean) -> (boolean?);
  --RemovePlayerFromGameId: (self: {}, player: number, gameId: string, updateJoinable: boolean) -> (boolean?);
  RemovePlayerFromGame: (self: {}, player: Player, gameId: string, updateJoinable: boolean) -> (boolean?);
  --RemovePlayersFromGameId: (self: {}, players: {number}, gameId: string, updateJoinable: boolean) -> (boolean?);
  RemovePlayersFromGame: (self: {}, players: {Player}, gameId: string, updateJoinable: boolean) -> (boolean?);

  --UpdateRatingsId: (self: {}, ratingType: string, ranks: {number}, teams: {{number}}) -> (boolean?);
  UpdateRatings: (self: {}, ratingType: string, ranks: {number}, teams: {{Player}}) -> (boolean?);

  SetJoinable: (self: {}, gameId: string, joinable: boolean) -> (boolean?);
  RemoveGame: (self: {}) -> (boolean?);
  StartGame: (self: {}, gameId: string, joinable: boolean) -> (boolean?);	
}

function MatchmakingService.GetSingleton(options: {	MajorVersion: string | nil;	DisableRatingSystem: boolean | nil; DisableExpansions: boolean | nil;	DisableGlobalEvents: boolean | nil;} | nil): Singleton
  if options and options.MajorVersion ~= nil then
    local versionToGet = options.MajorVersion
    options.MajorVersion = nil
    local id = MatchmakingService.Versions[versionToGet]
    if id == nil then
      warn("Major version " .. tostring(options.MajorVersion) .. " not found.")
    end
    MatchmakingService.Singleton = require(id).GetSingleton(options)
    return MatchmakingService.Singleton
  end
  print("Retrieving MatchmakingService ("..MatchmakingService.Version..") Singleton.")
  if MatchmakingService.Singleton == nil then
    Players.PlayerRemoving:Connect(function(player)
      if MatchmakingService.Singleton.IsGameServer then
        MatchmakingService.Singleton:RemovePlayerFromGameId(player.UserId, MatchmakingService.Singleton:GetCurrentGameCode(), MatchmakingService.Singleton.UpdateJoinableOnLeave)
      end
      MatchmakingService.Singleton:RemovePlayerFromQueueId(player.UserId)
    end)
    MatchmakingService.Singleton = MatchmakingService.new(options)
    task.spawn(function()
      local mainJobId = getFromMemory(MainMemory, "MainJobId", 3)
      local now = DateTime.now().UnixTimestampMillis
      local isMain = mainJobId == nil or mainJobId[2] + 25000 <= now
      if isMain and not CLOSED then
        MainMemory:UpdateAsync("MainJobId", function(old)
          if old == nil or old[1] == mainJobId then
            return {game.JobId, now}
          end
          return nil
        end, 86400)
      end

      if options == nil or not options.DisableGlobalEvents then
        MessagingService:SubscribeAsync("MatchmakingServicePlayersAddedToQueue", function(message)					
          for _, v in ipairs(message["Data"]) do
            if Players:GetPlayerByUserId(v[1]) ~= nil then continue end
            MatchmakingService.Singleton.PlayerAddedToQueue:Fire(v[1], v[2], v[3], v[4])
          end
        end)

        MessagingService:SubscribeAsync("MatchmakingServicePlayersRemovedFromQueue", function(message)
          for _, v in ipairs(message["Data"]) do
            if Players:GetPlayerByUserId(v[1]) ~= nil then continue end
            MatchmakingService.Singleton.PlayerRemovedFromQueue:Fire(v[1], v[2], v[3], v[4])
          end
        end)

        while not CLOSED do
          task.wait(5)
          if #PLAYERSADDED > 0 then
            MessagingService:PublishAsync("MatchmakingServicePlayersAddedToQueue", PLAYERSADDED)
            table.clear(PLAYERSADDED)
          end

          if #PLAYERSREMOVED > 0 then
            MessagingService:PublishAsync("MatchmakingServicePlayersRemovedFromQueue", PLAYERSREMOVED)
            table.clear(PLAYERSREMOVED)
          end

          table.clear(PLAYERSADDEDTHISWAVE)
        end
      end
    end)
  end
  return MatchmakingService.Singleton
end

--- Sets the matchmaking interval.
-- @param newInterval The new matchmaking interval.
function MatchmakingService:SetMatchmakingInterval(newInterval: number)
  self.MatchmakingInterval = newInterval
end

--- Sets the min/max players.
-- @param map The map the player range applies to.
-- @param newPlayerRange The NumberRange with the min and max players.
function MatchmakingService:SetPlayerRange(map: string, newPlayerRange: NumberRange)
  if newPlayerRange.Max > 100 then
    warn("Maximum players has a cap of 100.")
  end
  self.PlayerRanges[map] = {
    ["MMS_NO_ROLE"] = {
      ["Min"] = newPlayerRange.Min,
      ["Max"] = newPlayerRange.Max
    }
  }
end

type RoleRange = {
  Min: number,
  Max: number
}

type MapRoles = { [string]: RoleRange }

--- Sets the min/max players.
-- @param map The map the player range applies to.
-- @param newMapRoles The MapRoles to apply
function MatchmakingService:SetMapRoles(map: string, newMapRoles: MapRoles)
  if newMapRoles.Max > 100 then
    warn("Maximum players has a cap of 100.")
  end

  self.PlayerRanges[map] = newMapRoles
end

--- Add a new game place.
-- @param name The name of the map.
-- @param id The place id to teleport to.
function MatchmakingService:AddGamePlace(name: string, id: number)
  self.GamePlaceIds[name] = id
  if not self.PlayerRanges[name] then
    self.PlayerRanges[name] = NumberRange.new(6, 10)
  end
end

--- Sets whether or not this is a game server.
-- Disables match finding coroutine if it is.
-- @param newValue A boolean that indicates whether or not this server is a game server.
-- @param updateJoinableOnLeave A boolean that indicates whether or not to update the joinable status when a player leaves.
function MatchmakingService:SetIsGameServer(newValue: boolean, updateJoinableOnLeave: boolean)
  self.IsGameServer = newValue
  self.UpdateJoinableOnLeave = updateJoinableOnLeave
end

--- Sets the starting mean of OpenSkill objects.
-- Do not modify this unless you know what you're doing.
-- @param newStartingMean The new starting mean.
function MatchmakingService:SetStartingMean(newStartingMean: number)
  self.StartingMean = newStartingMean
end

--- Sets the starting standard deviation of OpenSkill objects.
-- Do not modify this unless you know what you're doing.
-- @param newStartingStandardDeviation The new starting standing deviation.
function MatchmakingService:SetStartingStandardDeviation(newStartingStandardDeviation: number)
  self.StartingStandardDeviation = newStartingStandardDeviation
end

--- Sets the max gap in rating between party members.
-- @param newMaxGap The new max gap between party members.
function MatchmakingService:SetMaxPartySkillGap(newMaxGap: number)
  self.MaxPartySkillGap = newMaxGap
end

--- Sets the number of seconds between each queue expansion.
-- An expansion is 10 rounded skill level in each direction.
-- If a player is skill level 25, they get rounded to 30
-- @param newValue The new value, in seconds, of seconds between each queue expansion.
function MatchmakingService:SetSecondsBetweenExpansion(newValue: number)
  self.SecondsPerExpansion = newValue
end

--- Sets the delay, in seconds, for players before being put into the teleport queue.
-- @param newValue The new value, in seconds, of the delay
function MatchmakingService:SetFoundGameDelay(newValue: number)
  self.FoundGameDelay = newValue
end

--- Sets whether running games are joinable or not. If disabled, players will not be able to join running games and the matchmaking loop will completely skip running games.
-- @param newValue A boolean that indicates whether or not running games are joinable.
function MatchmakingService:SetRunningGamesJoinable(newValue: boolean)
  self.RunningGamesJoinable = newValue
end

--- Clears all memory aside from player data.
function MatchmakingService:Clear()
  print("Clearing memory")
  local times = 0
  local runningGames = MatchmakingService:GetAllRunningGames()
  times += #runningGames
  for _, v in ipairs(runningGames) do
    if v.value.joinable then
      times += 1
      JoinableGamesMemory:RemoveAsync(v.key)
    else
      times += 1
      NonJoinableGamesMemory:RemoveAsync(v.key)
    end
  end
  MainMemory:RemoveAsync("QueuedSkillLevels")
  MainMemory:RemoveAsync("MainJobId")
  times += 2
  local queuedMaps = getFromMemory(MemoryQueue, "QueuedMaps", 3)
  times += 3
  if queuedMaps == nil then return print("Total requests: " .. tostring(times)) end
  MemoryQueue:RemoveAsync("QueuedMaps")
  times += 1

  for i, map in ipairs(queuedMaps) do
    local mapQueue = self:GetQueue(map)
    times += 1
    MemoryQueue:RemoveAsync(map.."__QueuedRatingTypes")
    if mapQueue == nil then continue end
    for ratingType, skillLevelAndQueue in pairs(mapQueue) do
      for skillLevel, queue in pairs(skillLevelAndQueue) do
        times += 1
        MemoryQueue:RemoveAsync(map.."__"..ratingType.."__"..skillLevel)
      end
    end
  end
  
  print("Total requests: " .. tostring(times))
end

function MatchmakingService.new(options: {	MajorVersion: string | nil;	DisableRatingSystem: boolean | nil; DisableExpansions: boolean | nil;	DisableGlobalEvents: boolean | nil;} | nil)
  local Service = {}
  setmetatable(Service, MatchmakingService)
  Service.Options = options or {}
  Service.MatchmakingInterval = 3
  Service.PlayerRanges = {}
  Service.GamePlaceIds = {}
  Service.IsGameServer = false
  Service.UpdateJoinableOnLeave = false
  Service.MaxPartySkillGap = 50
  Service.PlayerAddedToQueue = Signal:Create()
  Service.PlayerRemovedFromQueue = Signal:Create()
  Service.FoundGame = Signal:Create()
  Service.GameCreated = Signal:Create()
  Service.FoundGameDelay = 0
  Service.ApplyCustomTeleportData = nil
  Service.ApplyGeneralTeleportData = nil
  Service.SecondsPerExpansion = 10
  Service.RunningGamesJoinable = true

  -- Clears the store in studio 
  if RunService:IsStudio() then 
    task.spawn(Service.Clear, Service)
  end

  task.spawn(function()
    local lastCheckMain = 0
    local mainJobId = getFromMemory(MainMemory, "MainJobId", 3)
    while not Service.IsGameServer and not CLOSED do
      task.wait(Service.MatchmakingInterval)
      local now = DateTime.now().UnixTimestampMillis
      if lastCheckMain + 10000 <= now then
        mainJobId = getFromMemory(MainMemory, "MainJobId", 3)
        lastCheckMain = now
        if mainJobId ~= nil and mainJobId[1] == game.JobId then
          MainMemory:UpdateAsync("MainJobId", function(old)
            if (old == nil or old[1] == game.JobId) and not CLOSED then
              return {game.JobId, now}
            end
            return nil
          end, 86400)
          mainJobId = {game.JobId, now}
        end
      end
      if mainJobId == nil or mainJobId[2] + 30000 <= now then
        MainMemory:UpdateAsync("MainJobId", function(old)
          if (old == nil or mainJobId == nil or old[1] == mainJobId[1]) and not CLOSED then
            return {game.JobId, now}
          end
          return nil
        end, 86400)
        mainJobId = {game.JobId, now}
      elseif mainJobId[1] == game.JobId then
        -- Check all games for open slots
        local parties = getFromMemory(MainMemory, "QueuedParties", 3)

        if Service.RunningGamesJoinable then
          local runningGames = Service:GetJoinableGames()
          for _, g in ipairs(runningGames) do
            local mem = g.value
            -- Only try to add players to joinable games (sanity check)
            if mem.joinable then

              print("Checking running game")
              print(mem)

              -- Get the queue for this map, if there is no one left in the queue, skip it
              local q = Service:GetQueue(mem.map)
              if q == nil then 
                MemoryQueue:UpdateAsync("QueuedMaps", function(old)
                  if old == nil then return nil end
                  local index = table.find(old, mem.map)
                  if index == nil then return nil end
                  table.remove(old, index)
                  return old
                end, 86400)
                continue
              end

              -- Get the queue for this rating type, if there is no one left in the queue, skip it
              local queue = q[mem.ratingType]
              if queue == nil then continue end

              local rolesToCheck = {}

              for role, full in mem.full do
                if not full then
                  table.insert(rolesToCheck, role)
                end
              end

              for _, role in ipairs(rolesToCheck) do
                -- Finally get the queue for the skill level and role, if there is no one left in the queue, skip it
                local _queue = queue[tostring(mem.skillLevel)]

                if _queue == nil then continue end
                _queue = _queue[role]

                if _queue == nil or #_queue == 0 then continue end

                -- Get the number of expansions
                local expansions = if not Service.Options.DisableExpansions then math.floor((now-mem.createTime)/(Service.SecondsPerExpansion*1000)) else 0

                -- If there is no one queued at this skill level, and there are no expansions, skip it
                if _queue == nil and expansions == 0 then continue end

                -- Get the first values of the queue up to until the game is full
                local values = first(_queue or {}, Service.PlayerRanges[mem.map][role].Max - #mem.players)

                if not values or #values == 0 then continue end

                -- Check for, and apply, expansions
                if #values < Service.PlayerRanges[mem.map][role].Max - #mem.players then
                  for i = 1, expansions do

                    -- Skill difference is 10 per expansion in both directions
                    local skillUp = tostring(mem.skillLevel+10*i)
                    local skillDown = tostring(mem.skillLevel-10*i)
                    local queueUp = nil
                    local queueDown = nil

                    -- Get the queue at the rating type again
                    queueUp = q[mem.ratingType]
                    queueDown = q[mem.ratingType]

                    -- If there is anyone queued at the rating type, get the queue at the expanded skill level
                    if queueUp ~= nil then
                      if queueUp[skillUp] ~= nil then
                        queueUp = queueUp[skillUp][role]
                      end

                      if queueDown[skillDown] ~= nil then
                        queueDown = queueDown[skillDown][role]
                      end
                    end

                    -- Append these players to the end of the queue
                    append(values, queueUp)
                    append(values, queueDown)

                    -- Remove values that go past our necessary amount of players
                    if #values > Service.PlayerRanges[mem.map][role].Max - #mem.players then
                      for i = #values, Service.PlayerRanges[mem.map][role].Max - #mem.players, -1 do
                        table.remove(values, i)
                      end
                      break
                    end
                  end
                end

                -- If there is anyone, add them to the game
                if values ~= nil then

                  -- Remove all newly queued players
                  for j = #values, 1, -1 do
                    if values[j][2] >= now - Service.MatchmakingInterval*1000 then
                      table.remove(values, j)
                    end
                  end

                  -- Remove parties that won't fit into the game and skip them
                  local acc = #values
                  while not checkForParties(values) do
                    local f = first(_queue, Service.PlayerRanges[mem.map][role].Max - #mem.players, acc + 1)
                    if f == nil or #f == 0 then
                      break
                    end
                    acc += #f
                    append(values, f)
                  end
                end

                -- If there are any players left, add them to the game
                if values ~= nil and #values > 0 then
                  print("Adding to existing game")
                  local plrs = {}

                  local data = TeleportDataMemory:GetAsync(g.key) or {}

                  for _, v in ipairs(values) do
                    table.insert(plrs, v[1])
                    Service:SetPlayerInfoId(v[1], g.key, mem.ratingType, parties ~= nil and parties[v] or {}, mem.map, now + (Service.FoundGameDelay*1000))
                  end

                  Service:AddPlayersToGameId(plrs, g.key, role)

                  Service:RemovePlayersFromQueueId(tableSelect(values, 1), false)

                  if Service.ApplyCustomTeleportData ~= nil then
                    local gameData = Service.GetRunningGame(g.key)
                    for _, v in ipairs(plrs) do                
                      data.customData[v] = Service.ApplyCustomTeleportData(Players:GetPlayerByUserId(v), gameData)
                    end	
                  end

                  TeleportDataMemory:SetAsync(g.key, data, 86400)
                end
              end
            end
          end
        end

        -- Main matchmaking

        -- Get all of the queued maps, if there are none, skip everything
        local queuedMaps = getFromMemory(MemoryQueue, "QueuedMaps", 3)
        if queuedMaps == nil then continue end

        local playersAdded = {}

        -- For every map, execute the matchmaking loop
        for i, map in ipairs(queuedMaps) do

          -- Get the queue for this map, if there is none, skip it
          local mapQueue = Service:GetQueue(map)
          if mapQueue == nil then
            MemoryQueue:UpdateAsync("QueuedMaps", function(old)
              if old == nil then return nil end
              local index = table.find(old, map)
              if index == nil then return nil end
              table.remove(old, index)
              return old
            end, 86400)
            continue
          end

          -- For every rating type queued...
          for ratingType, skillLevelAndRoleQueue in pairs(mapQueue) do

            -- For every skill level queued...
            for skillLevel, roleQueue in pairs(skillLevelAndRoleQueue) do

              local toCreateAGame = {}

              -- For every role queued...
              for role, queue in pairs (roleQueue) do
                -- Get up to the maximum number of players for this map and role from the queue

                local values = first(queue, Service.PlayerRanges[map][role].Max)

                if not values or #values == 0 then continue end

                -- Get any expansions to the queue
                local expansions = if not Service.Options.DisableExpansions then math.floor((now-values[1][2])/(Service.SecondsPerExpansion*1000)) else 0

                -- Check for, and apply, expansions
                if values == nil or #values < Service.PlayerRanges[map][role].Max then
                  for i = 1, expansions do

                    -- Skill difference is 10 per expansion in both directions
                    local skillUp = tostring((tonumber(skillLevel) :: number)+10*i)
                    local skillDown = tostring((tonumber(skillLevel) :: number)-10*i)
                    local queueUp = nil
                    local queueDown = nil

                    -- Get the queue at the rating type
                    queueUp = mapQueue[ratingType]
                    queueDown = mapQueue[ratingType]

                    -- If there is anyone queued at the rating type, get the queue at the expanded skill level
                    if queueUp ~= nil then
                      if queueUp[skillUp] ~= nil then
                        queueUp = queueUp[skillUp][role]
                      end
                      if queueDown[skillDown] ~= nil then
                        queueDown = queueDown[skillDown][role]
                      end
                    end

                    -- Append these players to the end of the queue
                    if values == nil then values = {} end
                    append(values, queueUp)
                    append(values, queueDown)
                  end

                  -- Remove values that go past our necessary amount of players
                  if #values > Service.PlayerRanges[map][role].Max then
                    for i = #values, Service.PlayerRanges[map][role].Max, -1 do
                      table.remove(values, i)
                    end
                    break
                  end
                end

                if values ~= nil then
                  -- Remove all newly queued players
                  for j = #values, 1, -1 do
                    if values[j][2] >= now - Service.MatchmakingInterval*1000 then
                      table.remove(values, j)
                    end
                  end

                  -- Remove parties that won't fit into the game and skip them
                  local acc = #values
                  while not checkForParties(values) do
                    local f = first(queue, Service.PlayerRanges[map][role].Max, acc + 1)
                    if f == nil or #f == 0 then
                      break
                    end
                    acc += #f
                    append(values, f)
                  end

                  -- Remove players that already found a game (prevents double games with expansions)
                  for j = #values, 1, -1 do
                    if table.find(playersAdded, values[j][1]) then
                      table.remove(values, j)
                    end
                  end
                end

                -- If there aren't enough players than skip this skill level
                if values == nil or #values < Service.PlayerRanges[map][role].Min then
                  continue
                else
                  -- Get only the user ids from the players and add all of them to the playersAdded table
                  local userIds = tableSelect(values, 1)
                  append(playersAdded, userIds)

                  toCreateAGame[role] = userIds
                end
              end

              -- Create a game with the players we found
              local enoughToMakeGame = true 
              for role, range in pairs(Service.PlayerRanges[map]) do
                if toCreateAGame[role] == nil or #toCreateAGame[role] < range.Min then
                  enoughToMakeGame = false
                  break
                end
              end

              if enoughToMakeGame then
                print("WE GOT ENOUGH TO MAKE GAME!!!")
                -- Reserve a server and tell all servers the player is ready to join
                local reservedCode, serverId
                if RunService:IsStudio() then
                  reservedCode = "TEST"
                  serverId = "TEST"
                else
                  reservedCode, serverId = TeleportService:ReserveServer(Service.GamePlaceIds[map])
                end

                local gameData = {
                  ["full"] = {};
                  ["skillLevel"] = tonumber(skillLevel);
                  ["players"] = toCreateAGame;
                  ["started"] = false;
                  ["joinable"] = Service.RunningGamesJoinable;
                  ["ratingType"] = ratingType;
                  ["map"] = map;
                  ["createTime"] = now;
                }

                print("GAME DATA CREATED")

                for role, range in pairs(Service.PlayerRanges[map]) do
                  gameData.full[role] = toCreateAGame[role] and #toCreateAGame[role] >= range.Max
                end

                if gameData.joinable then
                  local allFull = true 
                  for role, full in pairs(gameData.full) do
                    if not full then
                      allFull = false
                      break
                    end
                  end

                  if allFull then
                    gameData.joinable = false
                  end

                end

                local success, err
                success, err = pcall(function()
                  if gameData.joinable then
                    print("Adding to joinable")
                    JoinableGamesMemory:UpdateAsync(reservedCode, function()
                      return gameData
                    end, 86400)
                  else
                    print("Adding to non-joinable")
                    NonJoinableGamesMemory:UpdateAsync(reservedCode, function()
                      return gameData
                    end, 86400)
                  end
                end)

                print("GAME DATA ADDED")

                if not success then
                  print("Error adding new game:")
                  warn(err)
                else
                  success, err = pcall(function()
                    MainMemory:SetAsync(serverId, reservedCode, 86400)
                  end)
                  if not success then
                    print("Error adding new game:")
                    warn(err)
                    continue
                  end
                  print("Added game")
                  Service.GameCreated:Fire(gameData, serverId, reservedCode)
                  local userIds = {}
                  for role, plrs in pairs(toCreateAGame) do
                    for _, v in ipairs(plrs) do
                      table.insert(userIds, v)
                      Service:SetPlayerInfoId(v, reservedCode, ratingType, parties ~= nil and parties[tostring(v)] or {}, map, now + (Service.FoundGameDelay*1000))
                    end
                  end
                  --Service:RemoveExpansions(ratingType, skillLevel)
                  Service:RemovePlayersFromQueueId(userIds, false)
                end
              end

            end
          end
        end

      end

      -- Teleport any players to their respective games
      local playersToTeleport = {}
      local playersToRatings = {}
      local playersToMaps = {}
      local gameCodesToData = {}
      for _, v  in ipairs(Players:GetPlayers()) do
        if not v:GetAttribute("MMS_QUEUED") then
          continue 
        end

        local playerData = Service:GetPlayerInfoId(v.UserId)
        if playerData ~= nil and now >= playerData.teleportAfter then
          if not playerData.teleported and playerData.curGame ~= nil then                        
            local gameData = gameCodesToData[playerData.curGame]                        
            if not gameData then
              gameData = Service:GetRunningGame(playerData.curGame)
              gameCodesToData[playerData.curGame] = gameData
            end
            Service.FoundGame:Fire(v.UserId, playerData.curGame, gameData)

            if playersToTeleport[playerData.curGame] == nil then playersToTeleport[playerData.curGame] = {} end
            table.insert(playersToTeleport[playerData.curGame], v)
            playersToRatings[v.UserId] = playerData.ratingType
            playersToMaps[v.UserId] = playerData.map
            MainMemory:UpdateAsync(v.UserId, function(old)
              if old then
                old.teleported = true
              end
              return old
            end, 7200)
          end
        end
      end

      for code, players in pairs(playersToTeleport) do
        local data = {gameCode=code, ratingType=playersToRatings[players[1].UserId], customData={}}

        local gameData = gameCodesToData[code]

        if Service.ApplyCustomTeleportData ~= nil then
          for i, player in ipairs(players) do
            data.customData[player.UserId] = Service.ApplyCustomTeleportData(player, gameData)
            print(gameData)
          end
        end

        if Service.ApplyGeneralTeleportData ~= nil then
          data.gameData = Service.ApplyGeneralTeleportData(gameData)
        end

        TeleportDataMemory:SetAsync(code, data, 86400)

        if code ~= "TEST" then TeleportService:TeleportToPrivateServer(Service.GamePlaceIds[playersToMaps[players[1].UserId]], code, players, nil) end
      end
    end
  end)
  return Service
end

--- Gets the current game's code. This only works on game servers!
-- @return The game's code, or nil if it isn't a game server.
function MatchmakingService:GetCurrentGameCode(): string?
  if not self.IsGameServer or not game.PrivateServerId then
    return nil
  end
  if not _gameId then
    _gameId = MainMemory:GetAsync(game.PrivateServerId)
  end
  return _gameId
end

--- Gets a running game's data. This includes its code, ratingType,
--  and any general game data you applied through the ApplyGeneralTeleportData function.
--  This will not return custom player data, for that use GetUserData(player).
-- @param code The game's code.
-- @return The game's data, if there is any.
function MatchmakingService:GetGameData(code: string): {any?}?
  local toReturn = {}
  if not code then
    if not self.IsGameServer then return nil end
    code = self:GetCurrentGameCode()
  end
  local data = TeleportDataMemory:GetAsync(code)
  if not data then return nil end

  toReturn.gameCode = data.gameCode
  toReturn.ratingType = data.ratingType

  if data.gameData then
    for k, v in pairs(data.gameData) do
      toReturn[k] = v
    end
  end

  return toReturn
end

--- Gets a user's custom data for the game they are currently in.
--  This will return nil if they're not in a game, or if you haven't
--  applied any custom data.
-- @param player The player id to get the data of.
-- @return The player's custom teleport data.
function MatchmakingService:GetUserDataId(player: number): {any?}?
  local playerData = MatchmakingService:GetPlayerInfoId(player)
  if not playerData or not playerData.curGame then return nil end

  local gameData = TeleportDataMemory:GetAsync(playerData.curGame)

  if not gameData or not gameData.customData then return nil end

  return gameData.customData[tostring(player)]
end

--- Gets a user's custom data for the game they are currently in.
--  This will return nil if they're not in a game, or if you haven't
--  applied any custom data.
-- @param player The player to get the data of.
-- @return The player's custom teleport data.
function MatchmakingService:GetUserData(player: Player): {any?}?
  return MatchmakingService:GetUserDataId(player.UserId)
end

--- Turns an OpenSkill object into a single rating number.
-- @param openSkillObject The open skill object.
-- @return The single number representation of the object.
function MatchmakingService:ToRatingNumber(openSkillObject): number
  return OpenSkill.Ordinal(openSkillObject)
end

--- Gets or initializes a players OpenSkill object.
-- You should not edit this directly unless you
-- know what you're doing.
-- @param player The player id to get the OpenSkill object of.
-- @param ratingType The rating type to get.
-- @return The OpenSkill object (which is just 2 numbers).
function MatchmakingService:GetPlayerRatingId(player: number, ratingType: string): {mu: number, sigma: number}?
  if self.Options.DisableRatingSystem then return nil end
  local skill = SkillDatastore:GetAsync(ratingType.."__"..tostring(player))
  if not skill then
    local rating = OpenSkill.Rating(self.StartingMean, self.StartingStandardDeviation)
    SkillDatastore:SetAsync(ratingType.."__"..tostring(player), rating, {player})
    skill = rating
  end
  return skill
end

--- Gets or initializes a players OpenSkill object.
-- You should not edit this directly unless you
-- know what you're doing.
-- @param player The player to get the OpenSkill object of.
-- @param ratingType The rating type to get.
-- @return The OpenSkill object (which is just 2 numbers).
function MatchmakingService:GetPlayerRating(player: Player, ratingType: string): {mu: number, sigma: number}?
  return self:GetPlayerRatingId(player.UserId, ratingType)
end

--- Sets a player's skill.
-- You should not edit this directly unless you
-- know what you're doing.
-- @param player The player to set the rating of.
-- @param ratingType The rating type to set.
-- @param rating The new OpenSkill object.
function MatchmakingService:SetPlayerRatingId(player: number, ratingType: string, rating: {mu: number, sigma: number})
  if self.Options.DisableRatingSystem then return nil end
  SkillDatastore:SetAsync(ratingType.."__"..tostring(player), rating, {player})
end

--- Sets a player's skill.
-- You should not edit this directly unless you
-- know what you're doing.
-- @param player The player to set the rating of.
-- @param ratingType The rating type to set.
-- @param rating The new OpenSkill object.
function MatchmakingService:SetPlayerRating(player: Player, ratingType: string, rating: {mu: number, sigma: number})
  self:SetPlayerRatingId(player.UserId, ratingType, rating)
end

--- Clears the player info.
-- @param playerId The player id to clear.
function MatchmakingService:ClearPlayerInfoId(playerId: number)
  MainMemory:RemoveAsync(playerId)
end

--- Clears the player info.
-- @param player The player to clear.
function MatchmakingService:ClearPlayerInfo(player: Player)
  self:ClearPlayerInfoId(player.UserId)
end

type PlayerInfo = {
  curGame: string;
  teleported: boolean;
  ratingType: string;
  party: {number};
  map: string;
  teleportAfter: number;
}

--- Sets the player info.
-- @param player The player id to update.
-- @param code The game id that the player will teleport to, if any.
-- @param ratingType The rating type of their current game, if any.
-- @param party The player's party (table of user ids including the player).
-- @param map The player's queued map, if any.
-- @param teleportAfter The time after which the player will be teleported.
function MatchmakingService:SetPlayerInfoId(player: number, code: string, ratingType: string, party: {number}, map: string, teleportAfter: number)
  if self.Options.DisableRatingSystem then ratingType = "MMS_RatingDisabled" end
  MainMemory:SetAsync(player, {
    curGame = code,
    teleported = false,
    ratingType = ratingType,
    party = party,
    map = map,
    teleportAfter = (teleportAfter or 0)
  }, 7200)
end

--- Sets the player info.
-- @param player The player to update.
-- @param code The game id that the player will teleport to, if any.
-- @param ratingType The rating type of their current game, if any.
-- @param party The player's party (table of user ids including the player).
-- @param map The player's queued map, if any.
-- @param teleportAfter The time after which the player will be teleported.
function MatchmakingService:SetPlayerInfo(player: Player, code: string, ratingType: string, party: {number}, map: string, teleportAfter: number)
  self:SetPlayerInfoId(player.UserId, code, ratingType, party, map, teleportAfter)
end

--- Gets the player info.
-- @param player The player id to get.
-- @return The player info.
function MatchmakingService:GetPlayerInfoId(player: number): PlayerInfo
  return getFromMemory(MainMemory, player, 3)
end

--- Gets the player info.
-- @param player The player to get.
-- @return The player info.
function MatchmakingService:GetPlayerInfo(player: Player)
  return self:GetPlayerInfoId(player.UserId)
end

--- Counts how many players are in the queues.
-- @return A dictionary of {map: {ratingType: {role: count}}} and the full count.
function MatchmakingService:GetQueueCounts(): ({any}, number)
  local counts = {}
  local queuedMaps = getFromMemory(MemoryQueue, "QueuedMaps", 3)
  if queuedMaps == nil then return end

  local totalCount = 0

  for i, map in ipairs(queuedMaps) do
    counts[map] = {}
    local mapQueue = self:GetQueue(map)
    if mapQueue == nil then continue end
    for ratingType, skillLevelAndQueue in pairs(mapQueue) do
      counts[map][ratingType] = {}
      for skillLevel, roleQueue in pairs(skillLevelAndQueue) do
        for role, queue in pairs(roleQueue) do
          local c = #queue
          counts[map][ratingType][role] = c
          totalCount += c
        end
      end
    end
  end
  return counts, totalCount
end

--- Gets joinable games from memory
-- @return An array of {key: gameCode, value: gameData} dictionaries
function MatchmakingService:GetJoinableGames(): {any}
  local bound = nil
  local toReturn = {}
  while true do
    local runningGames = JoinableGamesMemory:GetRangeAsync(Enum.SortDirection.Ascending, 200, bound)
    if #runningGames == 0 then
      break
    end
    bound = runningGames[#runningGames].key

    for _, v in ipairs(runningGames) do
      table.insert(toReturn, v)
    end

    if #runningGames < 200 then
      break
    end
  end

  return toReturn
end

--- Gets non-joinable games from memory
-- @return An array of {key: gameCode, value: gameData} dictionaries
function MatchmakingService:GetNonJoinableGames(): {any}
  local bound = nil
  local toReturn = {}
  while true do
    local runningGames = NonJoinableGamesMemory:GetRangeAsync(Enum.SortDirection.Ascending, 200, bound)
    if #runningGames == 0 then
      break
    end
    bound = runningGames[#runningGames].key

    for _, v in ipairs(runningGames) do
      table.insert(toReturn, v)
    end

    if #runningGames < 200 then
      break
    end
  end

  return toReturn
end


--- Gets all running games from memory
-- @return An array of {key: gameCode, value: gameData} dictionaries
function MatchmakingService:GetAllRunningGames(): {any}
  local bound = nil
  local toReturn = {}
  while true do
    local runningGames = JoinableGamesMemory:GetRangeAsync(Enum.SortDirection.Ascending, 200, bound)
    if #runningGames == 0 then
      break
    end
    bound = runningGames[#runningGames].key

    for _, v in ipairs(runningGames) do
      table.insert(toReturn, v)
    end

    if #runningGames < 200 then
      break
    end
  end

  while true do
    local runningGames = NonJoinableGamesMemory:GetRangeAsync(Enum.SortDirection.Ascending, 200, bound)
    if #runningGames == 0 then
      break
    end
    bound = runningGames[#runningGames].key

    for _, v in ipairs(runningGames) do
      table.insert(toReturn, v)
    end

    if #runningGames < 200 then
      break
    end
  end

  return toReturn
end

--- Gets joinable games from memory with a filter
-- @param max The maximum number of games to get
-- @param filter A filter function which is passed the game data. Should return true if passed
-- @return An array of {key: gameCode, value: gameData} dictionaries
function MatchmakingService:GetJoinableGamesFiltered(max: number, filter: (any) -> (boolean)): {any}
  local bound = nil
  local shouldBreak = false
  local toReturn = {}
  repeat
    local runningGames = JoinableGamesMemory:GetRangeAsync(Enum.SortDirection.Ascending, if max > 200 then 200 else max, bound)
    if #runningGames == 0 then
      break
    end
    bound = runningGames[#runningGames].key

    if (max <= 200 and #runningGames <= max) or (max > 200 and #runningGames < 200) then
      shouldBreak = true
    end

    if filter then
      for i = #runningGames, 1, -1 do
        if not filter(runningGames[i].value) then
          table.remove(runningGames, i)
        end
      end
    end

    for _, v in ipairs(runningGames) do
      table.insert(toReturn, v)
      if #toReturn == max then
        shouldBreak = true
        break
      end
    end
  until #toReturn == max or shouldBreak

  return toReturn
end

--- Gets non-joinable games from memory with a filter
-- @param max The maximum number of games to get
-- @param filter A filter function which is passed the game data. Should return true if passed
-- @return An array of {key: gameCode, value: gameData} dictionaries
function MatchmakingService:GetNonJoinableGamesFiltered(max: number, filter: (any) -> (boolean)): {any}
  local bound = nil
  local shouldBreak = false
  local toReturn = {}
  repeat
    local runningGames = NonJoinableGamesMemory:GetRangeAsync(Enum.SortDirection.Ascending, if max > 200 then 200 else max, bound)
    if #runningGames == 0 then
      break
    end
    bound = runningGames[#runningGames].key

    if (max <= 200 and #runningGames <= max) or (max > 200 and #runningGames < 200) then
      shouldBreak = true
    end

    if filter then
      for i = #runningGames, 1, -1 do
        if not filter(runningGames[i].value) then
          table.remove(runningGames, i)
        end
      end
    end

    for _, v in ipairs(runningGames) do
      table.insert(toReturn, v)
      if #toReturn == max then
        shouldBreak = true
        break
      end
    end
  until #toReturn == max or shouldBreak

  return toReturn
end

--- Gets a running game from memory by its code.
-- @param code The unique code of the game.
-- @return The game data, or nil if there is no data.
function MatchmakingService:GetRunningGame(code: string): {any}?
  if not code then
    if not self.IsGameServer then return nil end
    code = self:GetCurrentGameCode()
  end
  local gameData = getFromMemory(JoinableGamesMemory, code, 2) or getFromMemory(NonJoinableGamesMemory, code, 2)
  if typeof(gameData) == "table" then return gameData else return nil end
end

--- Gets a table of user ids, ratingTypes, and skillLevels in a specific queue.
-- @param map The map to get the queue of.
-- @return A dictionary of {ratingType: {skillLevel: queue}} where rating type is the rating type, skill level is the skill level pool (a rounded rating) and queue is a table of user ids.
function MatchmakingService:GetQueue(map: string): {[string]: {[any]: {any}}}?
  local queuedRatingTypes = getFromMemory(MemoryQueue, map.."__QueuedRatingTypes", 3)
  if queuedRatingTypes == nil then return nil end
  local queue = {}
  for ratingType, ratingObj in pairs(queuedRatingTypes) do
    queue[ratingType] = {}
    for i, v in ipairs(ratingObj) do
      queue[ratingType][v[1]] = getFromMemory(MemoryQueue, map.."__"..ratingType.."__"..v[1], 3)
    end
  end
  return queue
end

--- Queues a player.
-- @param player The player id to queue.
-- @param ratingType The rating type to use.
-- @param map The map to queue them on.
-- @return A boolean that is true if the player was queued.
function MatchmakingService:QueuePlayerId(player: number, ratingType: string, map: string, role: string): boolean
  local now = DateTime.now().UnixTimestampMillis
  local deserializedRating = nil
  local roundedRating = 0
  if self.Options.DisableRatingSystem then 
    ratingType = "MMS_RatingDisabled" 
  else
    deserializedRating = self:GetPlayerRatingId(player, ratingType)
    roundedRating = roundSkill(OpenSkill.Ordinal(deserializedRating))
  end
  local stringRoundedRating = tostring(roundedRating)

  if role == nil then
    role = "MMS_NO_ROLE"
  end

  local success, errorMessage

  local new = nil

  success, errorMessage = pcall(function()
    new = MemoryQueue:UpdateAsync(map.."__"..ratingType.."__"..stringRoundedRating, function(old)
      if old == nil then 
        old = {
          [role]={{player, now}}
        }
      elseif old[role] ~= nil then
        table.insert(old[role], {player, now})
      else
        old[role] = {{player, now}}
      end
      return old
    end, 86400)
  end)

  if not success then
    print("Unable to queue player:")
    warn(errorMessage)
  end

  updateQueue(map, ratingType, stringRoundedRating, role)

  
  local s = new ~= nil and find(new[role], function(v) return v[1] == player end) ~= nil

  if s and not self.Options.DisableGlobalEvents then
    self.PlayerAddedToQueue:Fire(player, map, ratingType, if self.Options.DisableRatingSystem then nil else roundedRating, role)

    local playerObj = Players:GetPlayerByUserId(player)
    if playerObj then
      playerObj:SetAttribute("MMS_QUEUED", true)
    end

    if table.find(PLAYERSADDEDTHISWAVE, player) == nil then
      local index = find(PLAYERSADDED, function(x)
        return x[1] == player
      end)
      if index == nil then
        table.insert(PLAYERSADDED, {player, map, ratingType, if self.Options.DisableRatingSystem then nil else roundedRating, role})
      end
      table.insert(PLAYERSADDEDTHISWAVE, player)
    end

    local index = find(PLAYERSREMOVED, function(x)
      return x[1] == player
    end)
    if index ~= nil then
      table.remove(PLAYERSREMOVED, index)
    end
  end

  return s
end

--- Queues a player.
-- @param player The player to queue.
-- @param ratingType The rating type to use.
-- @param map The map to queue them on.
-- @return A boolean that is true if the player was queued.
function MatchmakingService:QueuePlayer(player: Player, ratingType: string, map: string, role: string): boolean
  return self:QueuePlayerId(player.UserId, ratingType, map, role)
end

--- Queues a party.
-- @param players The player ids to queue.
-- @param ratingType The rating type to use.
-- @param map The map to queue them on.
-- @return A boolean that is true if the party was queued.
function MatchmakingService:QueuePartyId(players: {number}, ratingType: string, map: string, role: string): boolean
  local now = DateTime.now().UnixTimestampMillis
  local ratingValues = nil
  local avg = 0
  if self.Options.DisableRatingSystem then 
    ratingType = "MMS_RatingDisabled"
  else
    ratingValues = {}
    for _, v in ipairs(players) do
      ratingValues[v] = self:GetPlayerRatingId(v, ratingType)
      if any(ratingValues, function(r)
          return math.abs(OpenSkill.Ordinal(ratingValues[v]) - OpenSkill.Ordinal(r)) > self.MaxPartySkillGap
        end) then
        return false, v, "Rating disparity too high"
      end
      avg += OpenSkill.Ordinal(ratingValues[v])
    end

    avg = avg/dictlen(ratingValues)
  end
  local success, errorMessage

  local roundedRating = roundSkill(avg)
  local stringRoundedRating = tostring(roundedRating)

  if role == nil then
    role = "MMS_NO_ROLE"
  end

  local new = nil

  local tbl = {}

  for i, v in ipairs(players) do
    table.insert(tbl, {v, now, #players - i})
  end

  success, errorMessage = pcall(function()
    new = MemoryQueue:UpdateAsync(map.."__"..ratingType.."__"..stringRoundedRating, function(old)
      if old == nil then 
        old = {
          [role]={}
        }
      elseif old[role] == nil then
        old[role] = {}
      end
      for i, v in ipairs(tbl) do
        table.insert(old[role], v)
      end
      return old
    end, 86400)
  end)

  if not success then
    print("Unable to queue party:")
    warn(errorMessage)
  end

  local t = {}

  for _, v in ipairs(players) do
    t[v] = players
  end

  success, errorMessage = pcall(function()
    MainMemory:UpdateAsync("QueuedParties", function(old)
      if old == nil then old = {} end
      for k, v in pairs(t) do
        old[k] = v
      end
      return old
    end, 86400)
  end)

  if not success then
    print("Unable to update Queued Parties:")
    warn(errorMessage)
  end

  updateQueue(map, ratingType, stringRoundedRating)

  for _, v in ipairs(players) do
    if find(new[role], function(t) return t[1] == v end) == nil then
      self:RemovePlayersFromQueueId(players)
      return false, v, "Player not added to queue"
    end
  end

  for _, v in ipairs(players) do
    self.PlayerAddedToQueue:Fire(v, map, ratingType, if self.Options.DisableRatingSystem then nil else roundedRating)

    local playerObj = Players:GetPlayerByUserId(v)
    if playerObj then
      playerObj:SetAttribute("MMS_QUEUED", true)
    end

    if not self.Options.DisableGlobalEvents then
      if table.find(PLAYERSADDEDTHISWAVE, v) == nil then
        local index = find(PLAYERSADDED, function(x)
          return x[1] == v
        end)
        if index == nil then
          table.insert(PLAYERSADDED, {v, map, ratingType, if self.Options.DisableRatingSystem then nil else roundedRating})
        end
        table.insert(PLAYERSADDEDTHISWAVE, v)
      end

      local index = find(PLAYERSREMOVED, function(x)
        return x[1] == v
      end)
      if index ~= nil then
        table.remove(PLAYERSREMOVED, index)
      end
    end
  end

  return true
end

--- Queues a party.
-- @param player The players to queue.
-- @param ratingType The rating type to use.
-- @param map The map to queue them on.
-- @return A boolean that is true if the party was queued.
function MatchmakingService:QueueParty(players: {Player}, ratingType: string, map: string, role: string): boolean
  return self:QueuePartyId(tableSelect(players, "UserId"), ratingType, map, role)
end

--- Gets a player's party.
-- @param player The player id to get the party of.
-- @return A table of player id's of players in the party including this player.
function MatchmakingService:GetPlayerPartyId(player: number): {number}?
  local parties = getFromMemory(MainMemory, "QueuedParties", 3)
  if parties == nil or parties[player] == nil then 
    local playerInfo = self:GetPlayerInfo(player)
    print(playerInfo)
    for k, v in pairs(playerInfo) do
      print(k, v)
    end
    if playerInfo then return playerInfo.party end
    return nil
  end
  return parties[player]
end

--- Gets a player's party.
-- @param player The player to get the party of.
-- @return A table of player id's of players in the party including this player.
function MatchmakingService:GetPlayerParty(player: Player): {number}?
  return self:GetPlayerPartyId(player)
end


--- Removes a specific player id from the queue.
-- @param player The player id to remove from queue.
-- @return true if there was no error.
function MatchmakingService:RemovePlayerFromQueueId(player: number, updateAttribute: boolean): boolean?
  local toRemove = {}
  local hasErrors = false
  local success, errorMessage

  if updateAttribute == nil then
    updateAttribute = true
  end

  local queuedMaps = getFromMemory(MemoryQueue, "QueuedMaps", 3)

  if queuedMaps == nil then return end

  for i, map in ipairs(queuedMaps) do
    local queue = self:GetQueue(map)
    if queue == nil then 
      MemoryQueue:UpdateAsync("QueuedMaps", function(old)
        if old == nil then return nil end
        local index = table.find(old, map)
        if index == nil then return nil end
        table.remove(old, index)
        return old
      end, 86400)
      continue
    end
    for ratingType, skillLevelAndQueue in pairs(queue) do
      for skillLevel, roleQueue in pairs(skillLevelAndQueue) do
        for role, levelQueue in pairs(roleQueue) do
          if find(levelQueue, function(v) return v[1] == player end) then
            success, errorMessage = pcall(function()
              MemoryQueue:UpdateAsync(map.."__"..ratingType.."__"..skillLevel, function(old)
                if old == nil then return nil end
                local index = find(old[role], function(v) return v[1] == player end)
                if index == nil then return nil end
                table.remove(old[role], index)
                if #old[role] == 0 then
                  old[role] = nil
                end
                if next(old) == nil then 
                  table.insert(toRemove, map.."__"..ratingType.."__"..skillLevel)
                end

                self.PlayerRemovedFromQueue:Fire(player, map, ratingType, tonumber(skillLevel), role)

                if updateAttribute then
                  local playerObj = Players:GetPlayerByUserId(player)
                  if playerObj then
                    playerObj:SetAttribute("MMS_QUEUED", false)
                  end
                end

                if not self.Options.DisableGlobalEvents then
                  if table.find(PLAYERSADDEDTHISWAVE, player) == nil then
                    local index = find(PLAYERSREMOVED, function(x)
                      return x[1] == player
                    end)
                    if index == nil then
                      table.insert(PLAYERSREMOVED, {player, map, ratingType, tonumber(skillLevel), role})
                    end
                    table.insert(PLAYERSADDEDTHISWAVE, player)
                  end

                  local index = find(PLAYERSADDED, function(x)
                    return x[1] == player
                  end)
                  if index ~= nil then
                    table.remove(PLAYERSADDED, index)
                  end
                end

                return old
              end, 86400)
            end)

            if not success then
              hasErrors = true
              print("Unable to remove player from queue:")
              warn(errorMessage)
            end					
          end
        end
      end
    end
  end

  success, errorMessage = pcall(function()
    MainMemory:UpdateAsync("QueuedParties", function(old)
      if old == nil then return nil end
      old[player] = nil
      return old
    end, 86400)
  end)

  if not success then
    print("Unable to update Queued Parties:")
    warn(errorMessage)
  end

  for i = #toRemove, 1, -1 do
    local str = toRemove[i]
    MemoryQueue:RemoveAsync(str)
    local map, ratingType, skillLevel = table.unpack(string.split(str, "__"))

    MemoryQueue:UpdateAsync(map.."__QueuedRatingTypes", function(old)
      if old == nil then 
        return nil
      elseif old[ratingType] ~= nil then
        local index = find(old, function(v) return v[1] == skillLevel end)
        if index ~= nil then
          table.remove(old[ratingType], index)
        end
        if #old[ratingType] == 0 then
          old[ratingType] = nil
        end
        if dictlen(old) == 0 then
          table.insert(toRemove, map.."__QueuedRatingTypes")
        end
      end
      return old
    end, 86400)

    if not success then
      hasErrors = true
      print("Unable to update Queued Rating Types:")
      warn(errorMessage)
    end
    table.remove(toRemove, i)
  end

  for i = #toRemove, 1, -1 do
    local str = toRemove[i]
    MemoryQueue:RemoveAsync(str)
    local map = table.unpack(string.split(str, "__"))

    MemoryQueue:UpdateAsync("QueuedMaps", function(old)
      if old == nil then 
        return nil
      else
        local index = table.find(old, map)
        if index ~= nil then
          table.remove(old, index)
        end
      end
      return old
    end, 86400)

    if not success then
      hasErrors = true
      print("Unable to update Queued Maps:")
      warn(errorMessage)
    end
    table.remove(toRemove, i)
  end

  return not hasErrors
end

--- Removes a specific player from the queue.
-- @param player The player to remove from queue.
-- @return true if there was no error.
function MatchmakingService:RemovePlayerFromQueue(player: Player, updateAttribute: boolean): boolean?
  return self:RemovePlayerFromQueueId(player.UserId, updateAttribute)
end

--- Removes a table of player ids from the queue.
-- @param players The player ids to remove from queue.
-- @return true if there was no error.
function MatchmakingService:RemovePlayersFromQueueId(players: {number}, updateAttribute: boolean): boolean?
  local toRemove = {}
  local hasErrors = false
  local success, errorMessage

  if updateAttribute == nil then
    updateAttribute = true
  end

  local queuedMaps = getFromMemory(MemoryQueue, "QueuedMaps", 3)

  if queuedMaps == nil then return end

  local playersToQueues = {}

  local queuedMapsToRemove = {}
  for i, map in ipairs(queuedMaps) do
    local queue = self:GetQueue(map)
    if queue == nil then
      table.insert(queuedMapsToRemove, i - #queuedMapsToRemove)
      continue
    end
    for ratingType, skillLevelAndQueue in pairs(queue) do
      for skillLevel, roleQueue in pairs(skillLevelAndQueue) do
        for role, levelQueue in pairs(roleQueue) do
          for i, player in ipairs(players) do
            if find(levelQueue, function(v) return v[1] == player end) then
              if not playersToQueues[map.."__"..ratingType.."__"..skillLevel] then
                playersToQueues[map.."__"..ratingType.."__"..skillLevel] = {}
              end
              table.insert(playersToQueues[map.."__"..ratingType.."__"..skillLevel], player)
            end
          end
        end
      end
    end
  end

  if #queuedMapsToRemove > 0 then
    for i = #queuedMapsToRemove, 1, -1 do
      table.remove(queuedMaps, i)
    end
    MemoryQueue:SetAsync("QueuedMaps", queuedMaps)
  end

  for id, plrs in pairs(playersToQueues) do
    success, errorMessage = pcall(function()
      MemoryQueue:UpdateAsync(id, function(old)
        if old == nil then return nil end
        local map, ratingType, skillLevel = table.unpack(string.split(id, "__"))
        for i, player in ipairs(plrs) do
          for role, queue in pairs(old) do
            local index = find(queue, function(v) return v[1] == player end)
            if index == nil then continue end
            table.remove(queue, index)
            if #queue == 0 then
              old[role] = nil
            end
            self.PlayerRemovedFromQueue:Fire(player, map, ratingType, tonumber(skillLevel), role)

            if updateAttribute then
              local playerObj = Players:GetPlayerByUserId(player)
              if playerObj then
                playerObj:SetAttribute("MMS_QUEUED", false)
              end
            end

            if not self.Options.DisableGlobalEvents then
              if table.find(PLAYERSADDEDTHISWAVE, player) == nil then
                local index = find(PLAYERSREMOVED, function(x)
                  return x[1] == player
                end)
                if index == nil then
                  table.insert(PLAYERSREMOVED, {player, map, ratingType, tonumber(skillLevel), role})
                end
                table.insert(PLAYERSADDEDTHISWAVE, player)
              end

              local index = find(PLAYERSADDED, function(x)
                return x[1] == player
              end)
              if index ~= nil then
                table.remove(PLAYERSADDED, index)
              end
            end

            break
          end
        end

        if next(old) == nil then 
          table.insert(toRemove, id)
        end

        return old
      end, 86400)
    end)

    if not success then
      hasErrors = true
      print("Unable to remove player from queue:")
      warn(errorMessage)			
    end		
  end

  success, errorMessage = pcall(function()
    MainMemory:UpdateAsync("QueuedParties", function(old)
      if old == nil then return nil end
      for i, player in ipairs(players) do
        old[player] = nil
      end
      return old
    end, 86400)
  end)

  if not success then
    print("Unable to update Queued Parties:")
    warn(errorMessage)
  end

  for i = #toRemove, 1, -1 do
    local str = toRemove[i]
    MemoryQueue:RemoveAsync(str)
    local map, ratingType, skillLevel = table.unpack(string.split(str, "__"))

    MemoryQueue:UpdateAsync(map.."__QueuedRatingTypes", function(old)
      if old == nil then 
        return nil
      elseif old[ratingType] ~= nil then
        local index = find(old, function(v) return v[1] == skillLevel end)
        if index ~= nil then
          table.remove(old[ratingType], index)
        end
        if #old[ratingType] == 0 then
          old[ratingType] = nil
        end
        if dictlen(old) == 0 then
          table.insert(toRemove, map.."__QueuedRatingTypes")
        end
      end
      return old
    end, 86400)

    if not success then
      hasErrors = true
      print("Unable to update Queued Rating Types:")
      warn(errorMessage)
    end
    table.remove(toRemove, i)
  end

  for i = #toRemove, 1, -1 do
    local str = toRemove[i]
    MemoryQueue:RemoveAsync(str)
    local map = table.unpack(string.split(str, "__"))

    MemoryQueue:UpdateAsync("QueuedMaps", function(old)
      if old == nil then 
        return nil
      else
        local index = table.find(old, map)
        if index ~= nil then
          table.remove(old, index)
        end
      end
      return old
    end, 86400)

    if not success then
      hasErrors = true
      print("Unable to update Queued Maps:")
      warn(errorMessage)
    end
    table.remove(toRemove, i)
  end

  return not hasErrors
end

--- Removes a table of players from the queue.
-- @param players The players to remove from queue.
-- @return true if there was no error.
function MatchmakingService:RemovePlayersFromQueue(players: {Player}, updateAttribute: boolean): boolean?
  return self:RemovePlayersFromQueueId(tableSelect(players, "UserId"), updateAttribute)
end

--- Adds a player id to a specific existing game.
-- @param player The player id to add to the game.
-- @param gameId The id of the game to add the player to.
-- @param updateJoinable Whether or not to update the joinable status of the game.
-- @return true if there was no error.
function MatchmakingService:AddPlayerToGameId(player: number, gameId: string, updateJoinable: boolean, role: string): boolean?
  if updateJoinable == nil then updateJoinable = true end
  if role == nil then
    role = "MMS_NO_ROLE"
  end
  local hasErrors = false
  local removeFromJoinable = false 
  local _gameData = nil
  local success, errorMessage = pcall(function()
    JoinableGamesMemory:UpdateAsync(gameId, function(old)
      if old ~= nil then
        if old.players[role] == nil then
          old.players[role] = {}
        end
        table.insert(old.players[role], player)
        for role, range in pairs(self.PlayerRanges[old.map]) do
          old.full[role] = old.players[role] and #old.players[role] >= range.Max
        end

        if updateJoinable then
          local allFull = true 
          for role, full in pairs(old.full) do
            if not full then
              allFull = false
              break
            end
          end

          if allFull then
            old.joinable = false
            removeFromJoinable = true 
            _gameData = old
            return nil
          end
        end
        return old
      else
        return nil
      end
    end, 86400)
  end)
  if not success then
    hasErrors = true
    print("Unable to update Running Games (Add player to game):")
    warn(errorMessage)
  end

  if removeFromJoinable then
    success, errorMessage = pcall(function()
      JoinableGamesMemory:RemoveAsync(gameId)
      NonJoinableGamesMemory:SetAsync(gameId, _gameData, 86400)
    end)
    if not success then
      hasErrors = true
      print("Unable to update Running Games (Add player to game update joinable):")
      warn(errorMessage)
    end
  end

  return not hasErrors
end

--- Adds a player to a specific existing game.
-- @param player The player to add to the game.
-- @param gameId The id of the game to add the player to.
-- @param updateJoinable Whether or not to update the joinable status of the game.
-- @return true if there was no error.
function MatchmakingService:AddPlayerToGame(player: Player, gameId: string, updateJoinable: boolean, role: string): boolean?
  return self:AddPlayerToGameId(player.UserId, gameId, updateJoinable, role)
end

--- Adds a table of player ids to a specific existing game.
-- @param players The player ids to add to the game.
-- @param gameId The id of the game to add the players to.
-- @param updateJoinable Whether or not to update the joinable status of the game.
-- @return true if there was no error.
function MatchmakingService:AddPlayersToGameId(players: {number}, gameId: string, updateJoinable: boolean, role: string): boolean?
  local hasErrors = false
  local removeFromJoinable = false 
  if role == nil then
    role = "MMS_NO_ROLE"
  end
  local _gameData = nil
  local success, errorMessage = pcall(function()
    JoinableGamesMemory:UpdateAsync(gameId, function(old)
      if old ~= nil then
        if old.players[role] == nil then
          old.players[role] = {}
        end
        for _, v in ipairs(players) do
          table.insert(old.players[role], v)
        end
        for role, range in pairs(self.PlayerRanges[old.map]) do
          old.full[role] = old.players[role] and #old.players[role] >= range.Max
        end

        if updateJoinable then
          local allFull = true 
          for role, full in pairs(old.full) do
            if not full then
              allFull = false
              break
            end
          end

          if allFull then
            old.joinable = false
            removeFromJoinable = true 
            _gameData = old
            return nil
          end
        end
        return old
      else
        return nil
      end
    end, 86400)
  end) 
  if not success then
    hasErrors = true
    print("Unable to update Running Games (Add players to game):")
    warn(errorMessage)
  end

  if removeFromJoinable then
    success, errorMessage = pcall(function()
      JoinableGamesMemory:RemoveAsync(gameId)
      NonJoinableGamesMemory:SetAsync(gameId, _gameData, 86400)
    end)
    if not success then
      hasErrors = true
      print("Unable to update Running Games (Add player to game update joinable):")
      warn(errorMessage)
    end
  end

  return not hasErrors
end

--- Adds a table of players to a specific existing game.
-- @param players The players to add to the game.
-- @param gameId The id of the game to add the players to.
-- @param updateJoinable Whether or not to update the joinable status of the game.
-- @return true if there was no error.
function MatchmakingService:AddPlayersToGame(players: {Player}, gameId: string, updateJoinable: boolean, role: string): boolean?
  return self:AddPlayersToGameId(tableSelect(players, "UserId"), gameId, updateJoinable, role)
end

--- Removes a specific player id from an existing game.
-- @param player The player id to remove from the game.
-- @param gameId The id of the game to remove the player from.
-- @param updateJoinable Whether or not to update the joinable status of the game.
-- @return true if there was no error.
function MatchmakingService:RemovePlayerFromGameId(player: number, gameId: string, updateJoinable: boolean): boolean?
  local hasErrors = false
  local success, errorMessage = pcall(function()
    JoinableGamesMemory:UpdateAsync(gameId, function(old)
      if old ~= nil then
        local index = table.find(old.players, player)
        if index ~= nil then 
          table.remove(old.players, index)
        else
          return nil
        end
        old.full = #old.players == self.PlayerRanges[old.map].Max
        old.joinable = if updateJoinable then #old.players ~= self.PlayerRanges[old.map].Max else old.joinable
        return old
      else
        return nil
      end
    end, 86400)
  end)
  if not success then
    hasErrors = true
    print("Unable to update Running Games (Remove player from game):")
    warn(errorMessage)
  end
  return not hasErrors
end

--- Removes a specific player from an existing game.
-- @param player The player to remove from the game.
-- @param gameId The id of the game to remove the player from.
-- @param updateJoinable Whether or not to update the joinable status of the game.
-- @return true if there was no error.
function MatchmakingService:RemovePlayerFromGame(player: Player, gameId: string, updateJoinable: boolean): boolean?
  return self:RemovePlayerFromGameId(player.UserId, gameId, updateJoinable)
end

--- Removes multiple players from an existing game.
-- @param players The player ids to remove from the game.
-- @param gameId The id of the game to remove the player from.
-- @param updateJoinable Whether or not to update the joinable status of the game.
-- @return true if there was no error.
function MatchmakingService:RemovePlayersFromGameId(players: {number}, gameId: string, updateJoinable: boolean): boolean?
  local hasErrors = false
  local success, errorMessage = pcall(function()
    JoinableGamesMemory:UpdateAsync(gameId, function(old)
      if old ~= nil then
        for _, v in ipairs(players) do
          local index = table.find(old.players, v)
          if index == nil then continue end
          table.remove(old.players, index)
        end
        old.full = #old.players == self.PlayerRanges[old.map].Max
        old.joinable = if updateJoinable then #old.players ~= self.PlayerRanges[old.map].Max else old.joinable
        return old
      else
        return nil
      end
    end, 86400)
  end)

  if not success then
    hasErrors = true
    print("Unable to update Running Games (Remove players from game):")
    warn(errorMessage)
  end
  return not hasErrors
end

--- Removes multiple players from an existing game.
-- @param players The players to remove from the game.
-- @param gameId The id of the game to remove the player from.
-- @param updateJoinable Whether or not to update the joinable status of the game.
-- @return true if there was no error.
function MatchmakingService:RemovePlayersFromGame(players: {Player}, gameId: string, updateJoinable: boolean): boolean?
  return self:RemovePlayersFromGameId(tableSelect(players, "UserId"), gameId, updateJoinable)
end

--- Update player ratings after a game is over.
-- @param ratingType The rating type this is applicable for.
-- @param ranks The ranks of the teams. #scores should be the same as the #teams.
-- @param teams The teams. A table of tables which contain player ids.
-- @return true if there was no error.
function MatchmakingService:UpdateRatingsId(ratingType: string, ranks: {number}, teams: {{number}}): boolean?
  if self.Options.DisableRatingSystem then return nil end
  local hasErrors = false
  local success, errorMessage = pcall(function()
    local ratings = {}
    for i, team in ipairs(teams) do
      local teamRatings = {}
      for i, plr in ipairs(team) do
        table.insert(teamRatings, self:GetPlayerRatingId(plr, ratingType))
      end
      table.insert(ratings, teamRatings)
    end

    OpenSkill.Rate(ratings, { rank = ranks })

    for i, team in ipairs(ratings) do
      for j, rating in ipairs(team) do
        local plr = teams[i][j]
        self:SetPlayerRatingId(plr, ratingType, rating)
      end
    end

  end)
  if not success then
    hasErrors = true
    print("Unable to update Ratings:")
    warn(errorMessage)
  end
  return not hasErrors
end

--- Update player ratings after a game is over.
-- @param ratingType The rating type this is applicable for.
-- @param ranks The ranks of the teams. #scores should be the same as the #teams.
-- @param teams The teams. A table of tables which contain players.
-- @return true if there was no error.
function MatchmakingService:UpdateRatings(ratingType: string, ranks: {number}, teams: {{Player}}): boolean?
  local teamsIds = {}
  for i, team in ipairs(teams) do
    table.insert(teamsIds, tableSelect(team, "UserId"))
  end
  return self:UpdateRatingsId(ratingType, ranks, teamsIds)
end

--- Sets the joinable status of a game. This will remove it from memory if false.
-- @param gameId The id of the game to update.
-- @param joinable Whether or not the game will be joinable.
-- @return true if there was no error.
function MatchmakingService:SetJoinable(gameId: string, joinable: boolean): boolean?
  if not self.IsGameServer then return end

  local hasErrors = false

  if not joinable then
    gameId = gameId or self:GetCurrentGameCode()
    _gameData = getFromMemory(JoinableGamesMemory, gameId, 3) or _gameData
    _gameData.joinable = false
    local success, errorMessage = pcall(function()
      JoinableGamesMemory:RemoveAsync(gameId)
    end)

    if not success then
      hasErrors = true
      print("Unable to update Running Games (Update joinable false):")
      warn(errorMessage)
    end

    success, errorMessage = pcall(function()
      NonJoinableGamesMemory:SetAsync(gameId, _gameData, 86400)
    end)

    if not success then
      hasErrors = true
      print("Unable to update Running Games (Update joinable false 2):")
      warn(errorMessage)
    end
  else
    _gameData.joinable = true

    local success, errorMessage = pcall(function()
      NonJoinableGamesMemory:RemoveAsync(gameId)
    end)

    if not success then
      hasErrors = true
      print("Unable to update Running Games (Update joinable true):")
      warn(errorMessage)
    end

    success, errorMessage = pcall(function()
      JoinableGamesMemory:SetAsync(_gameId, _gameData, 86400)
    end)

    if not success then
      hasErrors = true
      print("Unable to update Running Games (Update joinable true 2):")
      warn(errorMessage)
    end
  end

  return not hasErrors
end

--- Removes this game from memory. Does not work on non-game servers.
-- @return true if there was no error.
function MatchmakingService:RemoveGame(): boolean?
  if not self.IsGameServer then return end
  local hasErrors = false
  local gameId = self:GetCurrentGameCode()
  local gameData = _gameData or getFromMemory(JoinableGamesMemory, gameId, 3)
  local success, errorMessage = pcall(function()
    JoinableGamesMemory:RemoveAsync(gameId)
  end)

  if not success then
    hasErrors = true
    print("Unable to update Running Games (Remove game):")
    warn(errorMessage)
  end

  success, errorMessage = pcall(function()
    MainMemory:RemoveAsync(game.PrivateServerId)
  end)

  if not success then
    hasErrors = true
    print("Unable to update Running Games (Remove game):")
    warn(errorMessage)
  end

  if gameData then
    for userId in ipairs(gameData.players) do
      self:ClearPlayerInfoId(userId)
    end
  end

  return not hasErrors
end

--- Starts a game.
-- @param gameId The game to start.
-- @param joinable Whether or not the game is still joinable.
-- @return true if there was no error.
function MatchmakingService:StartGame(gameId: string, joinable: boolean): boolean?
  if joinable == nil then joinable = false end
  if gameId == nil then gameId = self:GetCurrentGameCode() end
  local hasErrors = false
  local success, errorMessage = pcall(function()
    if joinable then
      JoinableGamesMemory:UpdateAsync(gameId, function(old)
        if old ~= nil then
          old.started = true
          old.joinable = joinable
          return old
        else
          if old == nil then
            warn("Unable to update Running Games (Start game): Invalid gameId.")
          else
            warn("Unable to update Running Games (Start game): No running games found in memory")
          end

          return nil
        end
      end, 86400)
    else
      _gameData = getFromMemory(JoinableGamesMemory, gameId, 3) or _gameData
      _gameData.joinable = false
      local success, errorMessage = pcall(function()
        JoinableGamesMemory:RemoveAsync(gameId)
      end)

      if not success then
        hasErrors = true
        print("Unable to update Running Games (Start game joinable false):")
        warn(errorMessage)
      end

      success, errorMessage = pcall(function()
        NonJoinableGamesMemory:SetAsync(gameId, _gameData, 86400)
      end)

      if not success then
        hasErrors = true
        print("Unable to update Running Games (Start game joinable false 2):")
        warn(errorMessage)
      end
    end
  end)

  if not success then
    hasErrors = true
    print("Unable to update Running Games (Start game):")
    warn(errorMessage)
  end
  return not hasErrors
end

if not RunService:IsStudio() then
  game:BindToClose(function()
    CLOSED = true
    local success, errorMessage = pcall(function()
      local mainId = getFromMemory(MainMemory, "MainJobId", 3)
      if mainId[1] == game.JobId then
        MainMemory:RemoveAsync("MainJobId")
      end
    end)

    local singleton = MatchmakingService.GetSingleton()
    if singleton.IsGameServer then
      singleton:RemoveGame()
    end
  end)
end


return MatchmakingService
