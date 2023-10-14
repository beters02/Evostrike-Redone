local rbxsignals = {}

function rbxsignals.DisconnectAllIn(tab: table)
    for i, v in pairs(tab) do
        if type(v) == "table" then
            tab[i] = rbxsignals.DisconnectAllIn(v)
        elseif typeof(v) == "RBXScriptConnection" then
            v:Disconnect()
            tab[i] = nil
        end
    end
    return tab
end

--@summary Disconnect a table value that is assumed to be a connection.
function rbxsignals.SmartDisconnect(value: RBXScriptConnection?)
    if value then
        value:Disconnect()
    end
end

--@summary Connect a connection in a table safely, checking for current connection
function rbxsignals.TableConnect(tab, key, connection): table?
    local success, result = pcall(function()
        if tab[key] and typeof(tab[key]) == "RBXScriptConnection" then
            tab[key]:Disconnect()
        end
        tab[key] = connection
        return tab
    end)
    if not success then
        warn(result)
        return tab
    end
    return result
end

return rbxsignals