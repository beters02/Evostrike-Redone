local abilityName = string.gsub(script.Parent.Parent.Name, "AbilityFolder_", "")
local abilityOptions = require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("Ability").Class[abilityName])
local abilityRemoteEvent = script.Parent.Parent.Remotes.AbilityRemoteEvent
local abilityRemoteFunction = script.Parent.Parent.Remotes.AbilityRemoteFunction
local serverStoredVar = {uses = abilityOptions.uses, cooldown = false}

local Functions = {}

local timerTypeKeys = {Cooldown = abilityOptions.cooldownLength}
Functions.Timer = function(timerType)
	local endTime = tick()
	local length = timerTypeKeys[timerType]
	if not length then error("Could not find timer " .. tostring(timerType)) end
	endTime += length
	repeat task.wait() until tick() >= endTime
	print('server cooldown finisehd')
	return true
end

Functions.GetVar = function()
    return serverStoredVar
end

Functions.CanUse = function()
	if not serverStoredVar.cooldown then
		if serverStoredVar.uses <= 0 then
			return false, "USES MISMATCH"
		end
		serverStoredVar.uses -= 1
		Functions.Timer("Cooldown")
		return serverStoredVar.uses
	end
    
    return false, "COOLDOWN MISMATCH"
end

abilityRemoteFunction.OnServerInvoke = function(player, action, ...)
    if not Functions[action] then return else return Functions[action](...) end
end