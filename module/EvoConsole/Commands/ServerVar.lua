local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local GameService = require(Framework.Service.GameService)

local ServerVar = {}

function ServerVar.Command(self, commandSplit)
    local key = string.gsub(commandSplit[1], "sv_", "")
    local value = commandSplit[2]
    local success, err = GameService:ChangeServerVar(key, value)
    if not success then
        return self:Error(err)
    end
    return self:Print(commandSplit[1] .. " " .. tostring(success))
end

return ServerVar