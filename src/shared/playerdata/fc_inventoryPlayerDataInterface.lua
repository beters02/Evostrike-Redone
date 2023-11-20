local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local PlayerData = require(Framework.Module.PlayerData)

local interface = {}

export type SkinInfo = {
    weapon: string,
    skin: string,
    model: string|nil
}

function interface:GetEquippedWeaponSkin(player: Player, weapon: string) -- returns skinInfo: {weapon: string, skin: string, model: string|nil}
    local skinInfo = {weapon = weapon, skin = nil, model = nil, uuid = nil}

    if RunService:IsClient() then
        skinInfo.skin = PlayerData:Get("inventory.equipped." .. string.lower(weapon))
    else
        skinInfo.skin = PlayerData.GetPlayerData(player).inventory.equipped[string.lower(weapon)]
    end

    local _sep = skinInfo.skin:split("_")
    local uuid = weapon == "knife" and _sep[3] or _sep[2]

    if not uuid or not tonumber(uuid) then
        local def = weapon == "knife" and "default_default" or "default"
        uuid = 0
        self:SetEquippedWeaponSkin(player, weapon, def, uuid)
        return self:GetEquippedWeaponSkin(player, weapon)
    end

    -- convert "model_Skin" into {"model", "skin"}
    if weapon == "knife" then
        _sep = self:SeperateKnifeSkinStrings(skinInfo.skin)
        skinInfo.skin, skinInfo.model = _sep.skin, _sep.model
    else
        skinInfo.skin = _sep[1]
    end

    skinInfo.uuid = uuid

    return skinInfo
end

function interface:SetEquippedWeaponSkin(player: Player, weapon: string, skin: string, uuid: number)
    if not uuid then return false end
    if RunService:IsClient() then
        local _pack = table.pack(PlayerData:Set("inventory.equipped." .. string.lower(weapon), skin .. "_" .. tostring(uuid)))
        PlayerData:Save()
        return table.unpack(_pack)
    else
        local pd = PlayerData.GetPlayerData(player)
        pd.inventory.equipped[string.lower(weapon)] = skin .. "_" .. tostring(uuid)
        return PlayerData.SetPlayerData(player, pd, true)
    end
end

function interface:SeperateKnifeSkinStrings(str: string)
    local _sep = str:split("_")
    return {model = _sep[1], skin = _sep[2]}
end

function interface:GetSkinInfoFromInvValue(key)
    local _sep = key:split("_")
    return {_sep[1], _sep[3] and _sep[3] or _sep[2], _sep[3] and _sep[2]} :: SkinInfo
end

-- checks for "*" TODO: merge SeperateKnifeSkinStrings and return all weapon_skin to SkinInfo {weapon, skin, model}
function interface:ParseInventoryData(inventory)
    for i, v in pairs(inventory) do
        if string.match(v, "*") then

            local skinfo = self:GetSkinInfoFromInvValue(v)
            if skinfo.skin == "*" then
                
            end
        end
    end
    return inventory
end

return interface