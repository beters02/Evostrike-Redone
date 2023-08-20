local Framework = require(game:GetService("ReplicatedStorage").Framework)
local statesloc = game:GetService("ReplicatedStorage"):WaitForChild("states")
local states = Framework.shm_states or Framework.__index(Framework, "shm_states")
local mainrf: RemoteFunction = statesloc:WaitForChild("remote").mainrf
local connections = {}

function init_connections()
    mainrf.OnServerInvoke = remote_main
end

function remote_getStateVar(stateName: string, key: string)
    return states[stateName].var[key]
end

function remote_setStateVar(stateName: string, key: string, value: any)
    -- add some verification eventually
    states[stateName].var[key] = value
    return states[stateName].var[key]
end

function remote_main(player, action, ...)
    if action == "getVar" then
        return remote_getStateVar(...)
    elseif action == "setVar" then
        return remote_setStateVar(...)
    end
end