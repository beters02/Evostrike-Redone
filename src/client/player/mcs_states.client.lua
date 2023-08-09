local statesloc = game:GetService("ReplicatedStorage"):WaitForChild("states")
local states = require(statesloc)
local mainrf: RemoteFunction = statesloc:WaitForChild("remote").mainrf
local connections = {}

function init_connections()
    mainrf.OnClientInvoke = remote_main
end

function remote_getStateVar(stateName: string, key: string)
    return states[stateName].var[key]
end

function remote_setStateVar(stateName: string, key: string, value: any)
    states[stateName].var[key] = value
    return states[stateName].var[key]
end

function remote_main(action, ...)
    if action == "getVar" then
        return remote_getStateVar(...)
    elseif action == "setVar" then
        return remote_setStateVar(...)
    end
end