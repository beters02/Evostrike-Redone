local Tables = {}

function Tables.Copy(t)
    local n = {}
    for i, v in pairs(t) do
        if type(v) == "table" then
            n[i] = Tables.Copy(t)
        else
            n[i] = v
        end
    end
    return n
end

-- t1 inherits properties from t2. creates copy of t1
function Tables.Inherit(t1, t2)
    local t = Tables.Copy(t1)
    for i, v in pairs(t2) do
        t[i] = v
    end
    return t
end

function Tables.PrintTable(t: table, sort: boolean?, callback: (any, any) -> ()?)
    if sort then
        table.sort(t)
    end
    callback = callback or function(i, v)
        print("[ " .. tostring(i) .. " : " .. tostring(v) .. " ]")
    end
    for i, v in pairs(t) do
        callback(i, v)
    end
end

local Strings = {}

function Strings.ToWordsArray(str)
    local t = {}
    for word in str:gmatch("%S+") do
        table.insert(t, word)
    end
    return t
end

local Math = {}

local Tweens = {}

function Tweens.Cancel(t: Tween)
    if t.PlaybackState == Enum.PlaybackState.Begin or t.PlaybackState == Enum.PlaybackState.Playing then
        t:Cancel()
    end
end

function Tweens.Pause(t: Tween)
    if t.PlaybackState == Enum.PlaybackState.Begin or t.PlaybackState == Enum.PlaybackState.Playing then
        t:Pause()
    end
end

local Connections = {}

function Connections.Disconnect(conn: RBXScriptConnection?)
    if conn then
        conn:Disconnect()
    end
end

return {Tables = Tables, Strings = Strings, Math = Math, Tweens = Tweens, Connections = Connections}