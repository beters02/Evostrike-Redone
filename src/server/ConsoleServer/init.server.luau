local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Admins = require(game:GetService("ServerStorage"):WaitForChild("Stored").AdminIDs)
local ConsoleEvents = ReplicatedStorage:WaitForChild("ConsoleEvents")
local RemoteEvent = ConsoleEvents:WaitForChild("RemoteEvent")
local RemoteFunction = ConsoleEvents:WaitForChild("RemoteFunction")

local InvokeActions = {
    Init = function(player)
        if not Admins:IsAdmin(player) then
            return false
        end
        local c = script.Admin:Clone()
        c.Parent = player
        return c
        --return require(script.Admin)
    end
}

local function Invoked(player, action, ...)
    return InvokeActions[action](player, ...)
end

RemoteFunction.OnServerInvoke = Invoked