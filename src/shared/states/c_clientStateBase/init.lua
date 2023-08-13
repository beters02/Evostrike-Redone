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
	return self
end

function base:get(player, key)
	if RunService:IsServer() then
		return mainrf:InvokeClient(player, self.Name, "GetState", key)
	end

	return self.var[key]
end

function base:set(player, key, value)
	if RunService:IsServer() then
		return mainrf:InvokeClient(player, self.Name, "SetState", key, value)
	end

	self.var[key] = value
	return self.var[key]
end

return base