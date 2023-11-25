

--@type
-- a TShopItem is a lowercase string containing information about the item.
-- {itemType_itemName}
-- itemType == "skin" {skin_weaponName_skinName}
-- Examples: [ "key_weaponcase1" ] [ "premiumCredit" ] [ "skin_ak103_knight" ] [ "skin_knife_karambit_default" ]
export type TShopItem = string
export type TShopItemStr = TShopItem
--

return nil