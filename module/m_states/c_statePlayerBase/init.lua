--[[
    FrameworkType: Class

    The only connections this class will be responsible for are:
    PlayerAdded - add player to state
    PlayerRemoving - remove player from state

    All other connections are handeled in ServerScriptService.states.mss_main
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(Framework.shfc_tables.Location)

local mainrf: RemoteFunction = ReplicatedStorage.states.remote.mainrf

local base = {}
base.__index = base

function base.new(stateName: string, defaultVar: table)
	local self = setmetatable({}, base)
    self.stateName = stateName
	self.var = Tables.clone(defaultVar)

    self:connect()
	return self
end

function base:playerAddedAddToState(player)
    self.stored[player.Name] = Tables.clone(self.stored._default)
end

function base:playerRemovingRemoveFromState(player)
    self.stored[player.Name] = nil
end

function base:connect()
	Players.PlayerAdded:Connect(function(player) self:playerAddedAddToState(player) end)
	Players.PlayerRemoving:Connect(function(player) self:playerRemovingRemoveFromState(player) end)
end

function base:get(player, key)
	if RunService:IsClient() then
		return mainrf:InvokeServer("getVar", self.Name, key)
	else
		return self.stored[player.Name][key]
	end
end

function base:set(player, key, value)
	if RunService:IsClient() then
		return mainrf:InvokeServer("setVar", self.Name, key, value)
	else
		self.stored[player.Name][key] = value
		return self.stored[player.Name][key]
	end
end

return base