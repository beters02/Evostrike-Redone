export type OKey = { name: string, price_pc: number?, price_sc: number?, sell_sc: number? }

-- Key Object Creation
local OKey = {new = function(prop)
    prop = prop or {}
    local _okey = {
        name = "Weapon_Case_1",
        price_pc = 10,
        price_sc = 100,
        sell_sc = 65
    }:: OKey
    for i, v in pairs(prop) do
        _okey[i] = v
    end
    return _okey
end}

local Keys = {
    weaponcase1 = OKey.new({name = "Weapon Case 1 Key"}):: OKey
}

return Keys