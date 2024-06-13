local SkinsDatabase = require(game:GetService("ServerStorage").SkinsDatabase)
local IIS = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("InventoryInterface"):WaitForChild("Shared"))

local invSkin = IIS.ParseSkinString("knife_karambit_purplefade")
print(SkinsDatabase:GetSkinTextures(invSkin, "4"))