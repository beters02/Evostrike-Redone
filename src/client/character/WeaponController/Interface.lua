local interface = {}

function interface._init(WeaponController)
    setmetatable(interface, {__index = WeaponController})
end

return interface