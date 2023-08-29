local instance = {}
instance.__index = instance

-- Instancing for Instances that are made by .New
local _dotnew = {RaycastParams = RaycastParams}

function instance.New(class: string, properties: table)
    if _dotnew[class] then
        local _p = _dotnew[class].new()
        for i, v in pairs(properties) do
            _p[i] = v
        end
        return _p
    else
        
    end
end

return instance