local Players = game:GetService("Players")
local playerManager = {}

--[[

]]
function playerManager.new()
    playerManager.cache = {}
    return setmetatable({}, playerManager)
end

--[[
    Initialize the playerManager, which will initialize:
        - Stored Players
        - Validity of Stored Players
        - Stored Connections and Variables
]]
function playerManager:Init()
    self.players = {}

end

--[[
    Verify that all of the players in the queue are real and online.
]]
function playerManager:VerifyPlayersInQueue()
    
end

--[[
    Combines the current DataStore with the cache'd queuePlayerStore
]]
function playerManager:CombineStore()
    
end

return playerManager