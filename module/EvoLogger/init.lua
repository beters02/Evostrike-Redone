local RunService = game:GetService("RunService")
if RunService:IsClient() then return end

--[[ Type Def ]]
export type Array<T> = {[number]: T}
export type Logger = {
    GetThread: (id: string) -> (Thread),
    GetThreads: () -> (Array<Thread>)
}

export type ThreadLevel = "Error" | "Print" | "Warn" | "Debug"
export type Thread = {
    Stored: {
        Error: table,
        Print: table,
        Warn: table,
        Debug: table
    },
    
    Add: (self: Thread, level: ThreadLevel, value: string) -> (),
    Delete: (self: Thread, level: ThreadLevel) -> (),
    Clear: (Thread) -> (),
    Get: (Thread, ThreadLevel) -> ()
}

--[[ Logger Module]]
local Logger
Logger = {_threads = {}}

--[[ Thread Class ]]
local Thread
Thread = {
    new = function()
        local self = setmetatable({}, Thread):: Thread
        self.Stored = Thread.newStored()
        return setmetatable(self, Thread):: Thread
    end,
    newStored = function()
        return {Error = {}, Print = {}, Warn = {}, Debug = {}}
    end,
    getLevelPrint = function(level: ThreadLevel)
        return (level == "Error" and warn) or (level == "Warn" and warn) or print
    end,
    Add = function(self: Thread, level: ThreadLevel, value: string)
        table.insert(self[level], value)
    end,
    Delete = function(self)
        self = nil
    end,
    Clear = function(self)
        self.Stored = self.newStored()
    end,
    Get = function(self: Thread, level: ThreadLevel)
        local _print = Thread.getLevelPrint(level)
        for _, v in pairs(self.Stored[level]) do
            _print(string.upper(level) .. ": " .. v)
        end
    end
}

function Logger.GetThread(id: string)
    Logger._threads[id] = Logger._threads[id] or Thread.new()
    return Logger._threads[id]:: Thread
end

function Logger.GetThreads()
    return Logger._threads
end

return Logger:: Logger