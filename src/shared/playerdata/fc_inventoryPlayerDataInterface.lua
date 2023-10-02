local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local RunService = game:GetService("RunService")

local PlayerData

if RunService:IsServer() then
    PlayerData = require(Framework.Module.server.PlayerDataScript.m_serverPlayerData)
else
    PlayerData = require(Framework.Module.shared.PlayerData.m_clientPlayerData)
end

local interface = {}

export type SkinInfo = {
    weapon: string,
    skin: string,
    model: string|nil
}

function interface:GetEquippedWeaponSkin(player: Player, weapon: string) -- returns skinInfo: {weapon: string, skin: string, model: string|nil}
    local skinInfo = {weapon = weapon, skin = nil, model = nil}

    if RunService:IsClient() then
        skinInfo.skin = PlayerData:Get("inventory.equipped." .. string.lower(weapon))
    else
        skinInfo.skin = PlayerData.GetPlayerData(player).inventory.equipped[string.lower(weapon)]
    end

    -- convert "model_Skin" into {"model", "skin"}
    if weapon == "knife" then
        local _sep = self:SeperateKnifeSkinStrings(skinInfo.skin)
        skinInfo.skin, skinInfo.model = _sep.skin, _sep.model
    end

    return skinInfo
end

function interface:SetEquippedWeaponSkin(player: Player, weapon: string, skin: string)
    if RunService:IsClient() then
        local _pack = table.pack(PlayerData:Set("inventory.equipped." .. string.lower(weapon), skin))
        PlayerData:Save()
        return table.unpack(_pack)
    else
        local pd = PlayerData.GetPlayerData(player)
        pd.inventory.equipped[string.lower(weapon)] = skin
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