local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage.Framework)
local AbilityLoc = Framework.Ability.Location
local AbilityFunc = require(Framework.shfc_sharedAbilityFunctions.Location)

-- ability var
local abilityName = string.gsub(script.Parent.Parent.Name, "AbilityFolder_", "")
local abilityOptions = require(ReplicatedStorage.ability.class[abilityName])
local abilityRemoteEvent = script.Parent.Parent.Remotes.AbilityRemoteEvent
local abilityRemoteFunction = script.Parent.Parent.Remotes.AbilityRemoteFunction
local abilityObjects = ReplicatedStorage.ability.obj:WaitForChild(abilityName)

local grenadeEvent = ReplicatedStorage.ability.remote.grenade :: RemoteEvent
local serverStoredVar = {uses = abilityOptions.uses, cooldown = false}
local char = script.Parent.Parent.Parent
local player = game:GetService("Players"):GetPlayerFromCharacter(char)

--[[
	Base Functions
]]

local Functions = {}
local timerTypeKeys = {Cooldown = abilityOptions.cooldownLength}

Functions.Timer = function(timerType)
	local endTime = tick()
	local length = timerTypeKeys[timerType]
	if not length then error("Could not find timer " .. tostring(timerType)) end
	endTime += length
	repeat task.wait() until tick() >= endTime
	abilityRemoteEvent:FireClient(player, "CooldownFinished")
	print('server cooldown finisehd')
	return true
end

Functions.CanUse = function()
	if not serverStoredVar.cooldown then
		if serverStoredVar.uses <= 0 then
			return false, "USES MISMATCH"
		end
		serverStoredVar.uses -= 1
		task.spawn(function()
			Functions.Timer("Cooldown")
		end)
		return serverStoredVar.uses
	end
    
    return false, "COOLDOWN MISMATCH"
end

--[[
	Grenades
]]

-- init Grenade caster if ability is a grenade
local caster, casbeh
if abilityOptions.isGrenade then
	caster, casbeh = AbilityFunc.InitCaster(char, abilityOptions, abilityObjects)
	grenadeEvent:FireAllClients("Create", abilityOptions, abilityObjects)
end

Functions.ThrowGrenade = function(mouseHit: Vector3)
	local thrower = player
	if not abilityOptions.isGrenade or not mouseHit or not thrower then return false end
	if not Functions.CanUse() then return false end

	task.spawn(function()
		local serverGrenade = AbilityFunc.FireCaster(player, mouseHit, caster, casbeh, abilityOptions)
		serverGrenade.Transparency = 1
		grenadeEvent:FireAllClients("Fire", player, serverGrenade, mouseHit, abilityOptions, abilityOptions.RayHit)
	end)
	return true
end

--[[
	Connections
]]

abilityRemoteFunction.OnServerInvoke = function(player, action, ...)
    if not Functions[action] then return else return Functions[action](...) end
end