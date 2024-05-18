-- Quick module to analyze some potential memory leaks

local Debugger = {}

-- Check if table contains any connections when they're not supposed to.
function Debugger:PrepareTableConnect(tbl, id)
    local isBugged = false
    local wasStillConnected = {}
    for i, connection: RBXScriptSignal? in pairs(tbl) do
        pcall(function(conn: RBXScriptSignal?)
            if conn and conn.Connected then
                isBugged = true
                table.insert(wasStillConnected, i)
                warn("Debugger found connection still active in PrepareTableConnect: " .. id)
            end
        end, connection)
    end
    if isBugged then
        warn("Debugger found connection(s) still active in PrepareTableConnect for id: " .. id)
        for _, v in pairs(wasStillConnected) do
            warn(id .. " . index: " .. v)
        end
    else
        print("Debugger table id: " .. id .. " passed connection checks!")
    end
end

return Debugger