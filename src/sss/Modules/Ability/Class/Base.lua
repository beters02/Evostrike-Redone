--[[ Base AbilityClass ]]

local Base = {}
Base.__index = Base

function Base.new(abilityClassModule)
    if not abilityClassModule then warn("Must specify AbilityClassModule") return end
    local self = setmetatable(require(abilityClassModule), Base)
    return self
end

function Base:ServerUseVarCheck()
    local useSuccess, err = self.remoteFunction:InvokeServer("CanUse")
    if not useSuccess then
        return false, warn("ABILITY USE ERROR, " .. err)
    end

    local newUses = useSuccess
    self.uses = newUses
    print(self.uses)
    return self.uses
end

function Base:StartClientCooldown()
    self.cooldown = true
    task.delay(0.07, function()
        for i = self.cooldownLength, 0, -1 do
            if i == 0 then
                self.cooldown = false
                self.frame.Key.Text = self.key
                break
            end
            self.frame.Key.Text = tostring(i)
            task.wait(1)
        end
    end)
    
    --[[task.delay(0.02 + self.cooldownLength, function()
        self.cooldown = false
    end)]]
end

return Base