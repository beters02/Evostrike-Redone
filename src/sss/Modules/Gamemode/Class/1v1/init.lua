local G1v1 = {
	minimumPlayers = 2,
	maximumPlayers = 2,
	roundLength = 120,
    barrierLength = 3,
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

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Modules = Framework.ServerScriptService.Modules
local Ability = require(Modules.Ability)
local Weapon = require(Modules.Weapon)
local Signal = require(Framework.ReplicatedStorage.Modules.Signal)
local SetClientCameraPosEvent = Framework.ReplicatedStorage.Remotes.Camera.SetPos:: RemoteEvent
--local PlayerDamagedEvent = Framework.ReplicatedStorage.Remotes.Weapon.PlayerDamaged :: BindableEvent
local PlayerDamagedSignal = Signal.CreateSignal("PlayerDamaged", true)

local _roundOverGuiTemplate = Framework.ServerScriptService.Modules.Gamemode.Class["1v1"].PlayerWonGui

-- Game Loop
function G1v1:GameLoop(round: number) -- game loop using recursion

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
		return G1v1:GameLoop(self.currentRound)
	end
end


--[[
    Base Gamemode Functions
]]

-- Final Start (With Players) Function
-- Fired after all players have joined
local function StartWithPlayers(self, players)

	-- set var
	self.players = players
	self.currentRound = 1
	self.roundStatus = "loading"

	-- clean up the map files (temp, bots)
	task.spawn(function()
		local clear = {workspace:WaitForChild("Bots"), workspace:WaitForChild("Temp")}
		for _, folder in pairs(clear) do
			local name = folder.Name
			folder:Destroy()
			local _f = Instance.new("Folder")
            _f.Name = name
            _f.Parent = workspace
		end
	end)

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
	print("Gamemode " .. self.currentGamemode .. " started!")
	self:GameLoop(1)
end

local function WaitForPlayers(self, min)

	-- destroy current waiting thread
	self.waitingThread = nil

	-- create waiting thread
	self.waitingThread = task.spawn(function() 
		-- wait until max players have joined
		-- max is min in this case since it is a 1v1 gamemode.
		repeat
			task.wait(1)
		until #Players:GetPlayers() >= min

		-- start
		StartWithPlayers(self, Players:GetPlayers())

		-- destroy waiting thread
		self.waitingThread = nil
	end)

end

-- Start Waiting function
function G1v1:Start()
	local min = self.minimumPlayers or 1
	local p = Players:GetPlayers()
	
	if #p < min then
		-- set player camera position to a pre set position on the map
		-- posun: Vector3 - CFrame Position from workspace properties
		-- rotun: Vector3 - Unit of X and Y CFrame Orientation from workspace properties.
		--				  - Using the Z value will cause the camera to be rotated on a slant. If you don't unit the vector, the rotation will be off.
		local posvec = Vector3.new(46.167, 41.093, -102.603)
		local rotun = Vector3.new(-29.61, -53.521, -0).Unit
		SetClientCameraPosEvent:FireClient(p[1], false, CFrame.new(posvec) * CFrame.fromEulerAngles(rotun.X, rotun.Y, 0)) -- NoCharacterCameraScript in StarterPlayerScripts. TODO: create a CameraScript

		WaitForPlayers(self, min)
		return
	end

	StartWithPlayers(self, Players:GetPlayers())
end


-- ForceStop
function G1v1:Stop()

	-- status
	self.roundStatus = "dead"

	-- disconnect connections
	if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
	if self.isWaiting then
		coroutine.yield(self.waitingThread)
	end

	-- destroy signal
	PlayerDamagedSignal.Destroy()

	-- remove all weapons and abilities
	Ability.ClearAllPlayerInventories()
	Weapon.ClearAllPlayerInventories()

	-- unload all characters
	for i, v in pairs(Players:GetPlayers()) do
		if not v.Character then continue end
		v.Character.Humanoid:TakeDamage(1000)
		v.Character = nil
	end

end


-- CharacterAdded Function
function G1v1:SpawnPlayer(player, spawnPart)
    if not player.Character then player:LoadCharacter() end
	local character = player.Character or player.CharacterAdded:Wait()

	-- connect death events
	character.Humanoid.Died:Once(function()
		self:Died(player)
	end)

	-- teleport player to spawn
	local Spawns = workspace:FindFirstChild("Spawns")
	local spawnLoc = Spawns and Spawns:FindFirstChild("Default")
	spawnLoc = spawnPart or spawnLoc or workspace.SpawnLocation

    print(spawnPart)

	character.PrimaryPart.Anchored = true
	character:SetPrimaryPartCFrame(spawnLoc.CFrame + Vector3.new(0,2,0))
	character.PrimaryPart.Anchored = false

	-- give player knife
	Ability.Add(player, "Dash")
	Ability.Add(player, "LongFlash")
	Weapon.Add(player, "AK47", true)
	Weapon.Add(player, "Glock17")
    Weapon.Add(player, "Knife")
end

function G1v1:GetPlayerSpawns()
    -- randomize players spawns
    local r = math.round(math.random(100, 200)/100)
    local r1 = r == 1 and 2 or 1
    return {r, r1}
end

-- Player Died Function
function G1v1:Died(player)
	self.ended:Fire("Died", self:_getOtherPlayer(player), player)
end

-- Player Damaged Round Event
function G1v1:PlayerDamaged(damaged, damager, damage) -- damaged: Character, damager: Character
	local damagedp = Players:GetPlayerFromCharacter(damaged)
	local damagerp = Players:GetPlayerFromCharacter(damager)
	self.roundPlayerData[damagerp.Name].rounddmg += damage
	print('Player damaged!')
end


--[[
    1v1 Gamemode Functions
]]


-- Starts round and specified RoundNumber
-- @return ended: BindableEvent - fires when ended
function G1v1:RoundStart(round: number)
	
	if self.ended then self.ended:Destroy() end
	self.ended = Instance.new("BindableEvent")
    self.bended = Instance.new("BindableEvent")

	-- disable any running connections
	self:_disconnectHotConns()

	-- status
	self.roundStatus = "running"

    -- spawn barriers
    local barriers = workspace:FindFirstChild("Barriers")
    if not barriers then barriers = ReplicatedStorage.Temp.Barriers end
    barriers.Parent = workspace

    -- kill players
    for i, v in pairs(self.players) do
        if v.Character and v.Character.Humanoid.Health > 0 then
            v.Character.Humanoid:TakeDamage(v.Character.Humanoid.Health + 1)
        end
    end

    task.wait(0.2)

    -- spawn players
    local randomSpawns = self:GetPlayerSpawns()
    local _c = 1
	for i, v in pairs(self.players) do
		self:SpawnPlayer(v, workspace.Spawns["Spawn" .. tostring(randomSpawns[_c])])
        _c += 1
	end

    -- start barrier timer
    local bendt = tick() + self.barrierLength
    --[[local bcte = self.barrierLength
    local bcurrentTime = self.barrierLength
    local blast = bcurrentTime

    table.insert(self.roundHotConnections, RunService.Heartbeat:Connect(function()
		if bendt and tick() >= bendt then self.bended:Fire() bendt = nil return end
		if not bendt then return end

		bcte = bendt - tick()
		bcurrentTime = math.floor(bcte)

		if bcurrentTime < blast then -- seconds update
			print(bcurrentTime)
		end
		
		blast = bcurrentTime
	end))]]

    repeat task.wait() until tick() >= bendt

    barriers.Parent = ReplicatedStorage.Temp

    -- round timer
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

	table.insert(self.roundHotConnections, PlayerDamagedSignal.Connect(function(damaged, damager, damage)
		self:PlayerDamaged(damaged, damager, damage)
	end))

	return self.ended
end


-- Ends round, decides whether or not game is over
-- @return gameEnd: boolean
-- @return winner: player - if over
-- @return loser: player - if over
function G1v1:RoundEnd(condition: string, ...): boolean

	-- status
	self.roundStatus = "loading"

	-- disable any running connections
	self:_disconnectHotConns()

	-- remove all weapons and abilities
	Ability.ClearAllPlayerInventories()
	Weapon.ClearAllPlayerInventories()

	-- player died shit
	if condition == "Died" then
        --TODO: insert this into hot connections
        task.wait(1.5) -- wait to allow players to round around
		return self:_roundEndPlayerDied(...)
	end

	-- ran out timer shit
	if condition == "Timer" then
        task.wait()
		return self:_roundEndTimerFinished()
	end

	return false
end

-- add up total player's damage stat &
-- reset rounddmg stat
function G1v1:_handleRoundEndDamageStats()
	for i, v in pairs(self.roundPlayerData) do
		v.totaldmg += v.rounddmg
		v.rounddmg = 0
	end
end

-- PlayerDied round end event func
function G1v1:_roundEndPlayerDied(...)
	local winner, loser = ...

	-- update data
	self.roundPlayerData[winner.Name].kills += 1
	self.roundPlayerData[winner.Name].roundWins += 1
	self.roundPlayerData[loser.Name].deaths += 1
	self:_handleRoundEndDamageStats()

	-- decide game end
	if self.roundPlayerData[winner.Name].roundWins >= self.roundsToWin then
		return true, winner, loser
	end

	return false
end

-- Timer Finished round event func
function G1v1:_roundEndTimerFinished()

	-- get random winner
	local r = math.round(math.random(100, 200)/100)
	local winner = self.players[r]
	local loser = self:_getOtherPlayer(winner)

	-- update data
	self.roundPlayerData[winner.Name].roundWins += 1
	self:_handleRoundEndDamageStats()

	-- decide game end
	if self.roundPlayerData[winner.Name].roundWins >= self.roundsToWin then
		return true, winner, loser
	end

	return false
end

--todo:
--add GUIAnimations
--add GUIAnimationFinished event, destroy server gui when fired
function G1v1:_handleRoundOverGui(winner)
    for i, v in pairs(Players:GetPlayers()) do
        local gui = _roundOverGuiTemplate:Clone()
        gui:WaitForChild("MainFrame").PlayerWonText = winner.Name .. " Won!"
        gui.Parent = v.PlayerGui
        gui.Enabled = true
        Debris:AddItem(gui, 2)
    end
end

--[[ GAME END FUNCTION ]]

-- Ends game under specified condition
-- @return void
function G1v1:GameEnd(condition: string, ...)
	self:Stop()
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