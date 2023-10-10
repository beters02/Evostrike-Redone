-- Evostrike Shop Items
export type ShopItem = {buy_sc: number | false, buy_pc: number | false, sell_sc: number | false, sell_pc: number | false}

local Items = {}

Items.Cases = { -- Each case will automatically make it's own "Key" in Items.Keys
    WeaponCase1 = {buy_sc = 20, buy_pc = 5, sell_sc = 10, sell_pc = false} :: ShopItem
}

Items.Keys = {
    WeaponCase1 = {buy_sc = 100, buy_pc = 25, sell_sc = 100, sell_pc = false}
}

Items.Skins = {
}

return Items