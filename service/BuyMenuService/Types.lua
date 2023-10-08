export type BuyMenuWeaponInventory = {primary: string?, secondary: string?, ternary: string?}
export type BuyMenuAbilityInventory = {primary: string?, secondary: string?}
export type BuyMenuPlayerInventory = {
    Weapon: BuyMenuWeaponInventory,
    Ability: BuyMenuAbilityInventory
}
export type BuyMenuPlayerData = {Player: Player, Inventory: BuyMenuPlayerInventory, BuyMenu: ScreenGui?, Connections: {}}

local Types = {}
Types.PlayerInventory = {}
Types.PlayerInventory.new = function() return {
    Weapon = {primary = false, secondary = false, ternary = false}:: BuyMenuWeaponInventory,
    Ability = {primary = false, secondary = false}:: BuyMenuAbilityInventory
} :: BuyMenuPlayerInventory end

Types.PlayerData = {}
Types.PlayerData.new = function(player) return {
    Player = player,
    BuyMenu = false,
    Inventory = Types.PlayerInventory.new(),
    Connections = {}
}:: BuyMenuPlayerData end

return Types