export type OKey = { name: string, price_pc: number?, price_sc: number?, sell_sc: number? }

-- Key Object Creation
local OKey = {new = function(prop)
    prop = prop or {}
    local _okey = {
        name = "Weapon_Case_1",
        price_pc = 100,
        price_sc = 1000,
        sell_sc = 1000*.75
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