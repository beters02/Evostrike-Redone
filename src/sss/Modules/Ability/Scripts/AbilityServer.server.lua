local abilityName = string.gsub(script.Parent.Parent.Name, "AbilityFolder_", "")
local abilityOptions = require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("Ability").Class[abilityName])
local abilityRemoteEvent = script.Parent.Parent.Remotes.AbilityRemoteEvent
local abilityRemoteFunction = script.Parent.Parent.Remotes.AbilityRemoteFunction
local serverStoredVar = {uses = abilityOptions.uses}

local Functions = {}

local timerTypeKeys = {Cooldown = abilityOptions.cooldownLength}
Functions.Timer = function(timerType)
	local endTime = tick()
	local length = timerTypeKeys[timerType]
	if not length then error("Could not find timer " .. tostring(timerType)) end
	endTime += length
	repeat task.wait() until tick() >= endTime
	return true
end

Functions.GetVar = function()
    return serverStoredVar
end

Functions.SubUses = function()
    serverStoredVar.uses -= 1
    return serverStoredVar.uses
end

abilityRemoteFunction.OnServerInvoke = function(player, action, ...)
    if not Functions[action] then return else return Functions[action](...) end
end