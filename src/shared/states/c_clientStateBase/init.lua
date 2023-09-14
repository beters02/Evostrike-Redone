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
	self.changedEvent = Instance.new("BindableEvent", ReplicatedStorage.temp)
	self.player = Players.LocalPlayer
	return self
end

function base:get(player, key)
	if RunService:IsServer() then
		return mainrf:InvokeClient(player, "getVar", self.Name, key)
	end

	return self.var[key]
end

function base:set(player, key, value)
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

-- Listen for changes, returns RBX signal
function base:changed(callback: (...any) -> (...any))
	return self.changedEvent.Event:Connect(callback)
end

-- Listen for changes only once, returns RBX signal
function base:changedOnce(callback: (...any) -> (...any))
	return self.changedEvent.Event:Once(callback)
end

return base