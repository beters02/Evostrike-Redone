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

local mainrf: RemoteFunction = ReplicatedStorage.Modules.m_states.remote.RemoteFunction

export type ClientState = {
	get: (player: Player, key: string) -> (any),
	set: (player: Player, key: string, value: any) -> (any)
}

---@interface The Base Class of a ClientState
local base = {}
base.__index = base

---@function Create a new state.
---@param stateName string -- The name of the State
---@param defaultVar table -- The starting Variables of the State
function base.new(stateName: string, defaultVar: table)
	local self = setmetatable({}, base)
    self.stateName = stateName
	self.var = Tables.clone(defaultVar)
	self.changedEvent = Instance.new("BindableEvent", ReplicatedStorage.temp)
	self.player = Players.LocalPlayer
	return self :: ClientState
end

---@function Get a variable from a State
---@param player Player -- The Player who owns the state.
---@param key any -- The key of the Variable
function base:get(player, key)
	if RunService:IsServer() then
		return mainrf:InvokeClient(player, "getVar", self.Name, key)
	end

	return self.var[key]
end

---@function Set a variable of a State
---@param player Player -- The Player who owns the state.
---@param key any -- The key of the Variable
---@param value any -- The new value of the Variable
function base:set(player, key, value)
	value = value or false
	if RunService:IsServer() then
		local new = mainrf:InvokeClient(player, "setVar", self.Name, key, value)

		if new then
			self.changedEvent:Fire(new)
			return new
		end

		return false
	end

	self.var[key] = value
	self.changedEvent:Fire(self.var[key])
	return self.var[key]
end

---@function Listen for changes, returns RBX signal
---@param callback thread -- The Function that runs on Event Fired.
function base:changed(callback: (...any) -> (...any))
	return self.changedEvent.Event:Connect(callback)
end

---@function -- Listen for changes only once, returns RBX signal
---@param callback thread -- The Function that runs on Event Fired.
function base:changedOnce(callback: (...any) -> (...any))
	return self.changedEvent.Event:Once(callback)
end

return base