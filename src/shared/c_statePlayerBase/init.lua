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
local Tables = Framework.shfc_tables.Module

local mainrf: RemoteFunction = ReplicatedStorage.states.remote.mainrf

local base = {}
base.__index = base

function base.new(stateName: string, defaults: table)
	local self = setmetatable({}, base)
    self.stateName = stateName
    self.stored = {_default = defaults}

    self:connect()
	return self
end

function base:playerAddedAddToState(player)
    self.Stored[player.Name] = Tables.clone(self.stored._default)
end

function base:playerRemvingRemoveFromState(player)
    self.Stored[player.Name] = nil
end

function base:connect()
	Players.PlayerAdded:Connect(function(player) self:playerAddedAddToState(player) end)
	Players.PlayerRemoving:Connect(function(player) self:playerRemvingRemoveFromState(player) end)
end

function base:get(player, key)
	if RunService:IsClient() then
		return mainrf:InvokeServer(self.Name, "GetState", key)
	else
		return self.Stored[player.Name][key]
	end
end

function base:set(player, key, value)
	if RunService:IsClient() then
		return mainrf:InvokeServer(self.Name, "SetState", key, value)
	else
		self.Stored[player.Name][key] = value
		return self.Stored[player.Name][key]
	end
end

return base