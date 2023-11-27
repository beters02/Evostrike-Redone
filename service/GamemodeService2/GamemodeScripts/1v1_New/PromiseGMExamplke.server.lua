local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Promise = require(Framework.Module.lib.c_promise)

local Team1 = Teams:WaitForChild("Team1")
local Team2 = Teams:WaitForChild("Team2")
-- there is a third team that players go to when they die :P

local function enoughPlayers()
	return #Players:GetPlayers() >= 2
end

-- promise that resolves when the passed in team has no players
local function teamWipedOutPromise(team)
	return Promise.fromEvent(team.PlayerRemoving, function()
		return #team:GetPlayers() <= 0
	end)
end

-- promise that resolves when enough players have joined the game
local function notEnoughPlayersPromise()
	return Promise.fromEvent(Players.PlayerRemoving, function()
		return #Players:GetPlayers() - 1 < 2
	end)
end

-- promise that resolves when there are no longer enough players
local function enoughPlayersPromise()
	return Promise.fromEvent(Players.PlayerAdded, function()
		return enoughPlayers()
	end)
end

function startGame()
	return Promise.race({
		teamWipedOutPromise(Team1) -- team2 win condition 1
			:andThenReturn(Team2), -- return team2, because they won :D

		teamWipedOutPromise(Team2) -- team1 win condition 1
			:andThenReturn(Team1), -- return team1, same reason :P

		Promise.resolve() -- team1 win condition 2
			:andThen(function()
				-- teleport + freeze all team1
				-- do a lil' countdown
			end)
			:andThenCall(Promise.delay, 5)
			:andThen(function()
				-- unfreeze team1
			end)
			:andThenCall(Promise.delay, 30)
			:andThen(function()
				-- teleport team2
			end)
			:andThenCall(Promise.delay, 300)
			:andThenReturn(Team1)
	})
		:andThen(function(winners)
			-- handle winners
		end)
		:andThenCall(Promise.delay, 5)
		:andThen(function()
			-- teleport players back to lobby
		end)
		:andThen(function() -- can't use andThenReturn here because of conditional
			return enoughPlayers() and intermit or waitForPlayers
			-- return the next block of code we should do!
		end)
end

function intermit()
	return Promise.race({
		notEnoughPlayersPromise()
			:andThenReturn(waitForPlayers),
			-- not enough players, so we go back to waiting for players :'(

		Promise.delay(30)
			:andThen(function()
				-- load the map
				-- assign teams
			end)
			:andThenReturn(startGame)
			-- we successfully finished intermission with enough players,
			-- so we should start the game >:D
	})
end

function waitForPlayers()
	return enoughPlayersPromise()
		:andThenReturn(intermit)
		-- enough players, so we can start the intermission! :D
end

local nextBlock = waitForPlayers

while true do
	nextBlock = nextBlock():expect()
end