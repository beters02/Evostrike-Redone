local Framework = require(game:GetService("ReplicatedStorage").Framework)
local statesloc = game:GetService("ReplicatedStorage"):WaitForChild("states")
local states = require(Framework.shm_states.Location)
local mainrf: RemoteFunction = statesloc:WaitForChild("remote").mainrf
local connections = {}

function init_connections()
    mainrf.OnClientInvoke = remote_main
end

function remote_getStateVar(stateName: string, key: string)
    return states._clientClassStore[stateName].var[key]
end

function remote_setStateVar(stateName: string, key: string, value: any)
    states._clientClassStore[stateName].var[key] = value
    return states[stateName].var[key]
end

function remote_main(action, ...)
    if action == "getVar" then
        return remote_getStateVar(...)
    elseif action == "setVar" then
        return remote_setStateVar(...)
    end
end