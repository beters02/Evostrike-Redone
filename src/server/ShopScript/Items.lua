-- Evostrike Shop Items
export type ShopItem = {buy_sc: number | false, buy_pc: number | false, sell_sc: number | false, sell_pc: number | false}

local Items = {}

Items.Cases = {
    weaponcase1 = {buy_sc = 20, buy_pc = 5, sell_sc = 10, sell_pc = false} :: ShopItem
}

Items.Keys = {
    weaponcase1 = {buy_sc = 100, buy_pc = 25, sell_sc = 100, sell_pc = false}
}

Items.Skins = {
    ak103 = {
        hexstripe = {buy_sc = 1000, sell_sc = 600, buy_pc = 100, sell_pc = false}
    },
    glock17 = {
        hexstripe = {buy_sc = 750, sell_sc = 450, buy_pc = 75, sell_pc = false}
    }
}

return Items