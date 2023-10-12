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

return rbxsignals