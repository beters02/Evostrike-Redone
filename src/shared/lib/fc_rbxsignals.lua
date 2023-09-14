local rbxsignals = {}

function rbxsignals.DisconnectAllIn(tab: table)
    for i, v in pairs(tab) do
        v:Disconnect()
    end
end

return rbxsignals