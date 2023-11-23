export type InventorySkinObject = {weapon: string, model: string, skin: string, uuid: string, unsplit: string}

function GetWeaponModule(weapon)
    return game.ReplicatedStorage.Services.WeaponService.Weapon:FindFirstChild(string.lower(weapon))
end

local Shared = {}

-- Remember that model will return weapon if weapon is not "knife".
function Shared.ParseSkinString(str: string)
    local split = str:split("_")
    return {weapon = split[1], model = split[2], skin = split[3], uuid = split[4], unsplit = str}:: InventorySkinObject
end

function Shared.GetSkinModelFromSkinObject(skin) -- Returns Default Skin if Necessary
    print(skin)
    local weaponModule = GetWeaponModule(skin.weapon)
    local success, model = pcall(function()
        if skin.weapon == "knife" then
            return weaponModule.Assets[skin.model].Models[skin.skin]
        end
        return weaponModule.Assets.Models[skin.skin]
    end)
    if success then
        return model
    end
    warn("Could not find skin for model " .. tostring(skin.weapon) .. "_" .. tostring(skin.skin) .. ". " .. tostring(model))
    return Shared.GetDefaultSkinForWeapon(skin.weapon)
end

function Shared.GetDefaultSkinForWeapon(weapon)
    if weapon == "knife" then
        return GetWeaponModule("knife").Assets.default.Models.default
    end
    return GetWeaponModule(weapon).Assets.Models.default
end

function Shared.GetSkinModelFromString(skinStr)
    return Shared.GetSkinModelFromSkinObject(Shared.ParseSkinString(skinStr))
end

return Shared