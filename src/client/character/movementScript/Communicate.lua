local tl = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework")).shfc_tables.Location
local tables = require(tl)
local comm = {}
comm.__index = comm

-- Init var

comm._sending = false
comm._getting = false
comm._got = false
comm._debounce = false

-- Init Movement Restrictions

-- Data Get/Sat

function comm.GetVar(key: any)
    if comm._getting then repeat task.wait() until not comm._getting end

    comm._getting = key
    repeat task.wait() until not comm._getting

    return comm._got
end

function comm.SetVar(key: string, var: any)

    -- set the module sending var to new variable
    -- this is listened to in the Movement client script.
    if not comm._sending then
        comm._sending = {}
    end

    comm._sending[key] = var

    return var
end

-- Data Listen

function comm._listenForChanges(self)
    if comm._sending then
        local _s = tables.clone(comm._sending)
        comm._sending = false
        return _s
    end

    if comm._getting then
        if comm._debounce then return end
        comm._debounce = true
        if type(comm._getting) == "table" then
            local _g = {}
            for i, v in pairs(comm._getting) do
                _g[i] = self[v]
            end
            comm._got = _g
        else
            comm._got = self[comm._getting]
        end
        comm._getting = false
        comm._debounce = false
    end
    return false
end

return comm