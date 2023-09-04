local RunService = game:GetService("RunService")

local service = {}
service.__index = function(self, ind)
    --if RunService:IsClient() then return false end
end

return service