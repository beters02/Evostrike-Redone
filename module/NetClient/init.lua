-- Module to unify Net Requests coming from the Client
-- Kinda WIP i cant think rn
if game:GetService("RunService"):IsServer() then return end

export type Request = {
    Callback: (...any) -> (...any),
    Time: number
}

-- CONFIG
local CLIENT_REQUEST_DELAY = 1

local NetClient = {
    LastRequestTime = 0,
    Requests = {}
}

function NetClient:MakeRequest(callback)
    if tick() - self.LastRequestTime < CLIENT_REQUEST_DELAY then
        repeat task.wait() until tick() - self.LastRequestTime >= 1
    end
    self.LastRequestTime = tick()
    return callback()
end

return NetClient