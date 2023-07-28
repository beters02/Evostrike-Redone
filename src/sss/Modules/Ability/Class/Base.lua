--[[ Base AbilityClass ]]

local Base = {}

function Base.new(abilityClassModule)
    if not abilityClassModule then warn("Must specify AbilityClassModule") return end

    local self = setmetatable(require(abilityClassModule), Base)
    return self
end

function Base:AttemptUse()
    
end

return Base