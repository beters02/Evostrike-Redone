local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")

export type DatabaseSkin = {
    Seed: number, -- 1 -> 100
    Wear: number,  -- 0.0001 -> 0.9999,
    Stickers: {first: string?, second: string?, third: string?, fourth: string?}
}

export type AssetIds = {
    metallic: string,
    smoothness: string,
    diffuseOriginal: string
}

local SkinsDB = {}

local function CreateSeededSkinAsset(invSkin, seed)
    local response = HttpService:RequestAsync({
        ["Method"] = "POST",
        ["Url"] = "http://localhost:8435",
        ["Headers"] = {
            ["Content-Type"] = "application/json"
        },
        ["Body"] = HttpService:JSONEncode({
            ["weapon"] = invSkin.weapon,
            ["model"] = invSkin.model,
			["skin"] = invSkin.skin,
			["seed"] = seed
        })
    })

    if not response then
        error("Did not recieve required body. " .. tostring(response))
    end
    response = HttpService:JSONDecode(response.Body)
    return {
        diffuseOriginal = response.diffuseOriginal,
        metallic = response.metallic,
        smoothness = response.smoothness,
    } :: AssetIds
end

function SkinsDB:GetSkinTextures(invSkin, seed)
    local store = DataStoreService:GetDataStore("SkinTexturesDatabase")
    local dataKey = invSkin.weapon .. "_" .. invSkin.model .. "_" .. invSkin.skin .. "_" .. seed
    local assetIds: AssetIds? = store:GetAsync(dataKey)

    if not assetIds then
        
    end
    assetIds = CreateSeededSkinAsset(invSkin, seed) :: AssetIds
    if not assetIds then
        return false
    end

    store:SetAsync(dataKey, assetIds)

    for i, v in pairs(assetIds) do
        local model = game:GetService("InsertService"):LoadAsset(v)
        model.Name = i
        model.Parent = workspace
    end

    print(assetIds)
end

function SkinsDB:GetSkin(invSkin)
    if invSkin.skin == "Default" or tostring(invSkin.uuid) == "0" then
        return
    end

    local store = DataStoreService:GetDataStore("SkinsDatabase")
    local dataKey = invSkin.model .. "_" .. invSkin.skin
    local changed = false
    local data

    if invSkin.weapon == "knife" then
        dataKey = "knife_" .. dataKey
    end

    data = store:GetAsync(dataKey)

    if not data then
        changed = true
        data = {}
    end

    if not data[invSkin.uuid] then
        changed = true
        data[invSkin.uuid] = {
            Seed = math.random(1, 100),
            Wear = math.random(1, 999) * 0.001,
            Stickers = {first = false, second = false, third = false, fourth = false}
        }:: DatabaseSkin
        print("Succesfully added skin to the database.")
    end

    if changed then
        store:SetAsync(dataKey, data)
    end

    return data[invSkin.uuid]
end

function SkinsDB:RemoveSkin(invSkin)
    local store = DataStoreService:GetDataStore("SkinsDatabase")
    local dataKey = invSkin.model .. "_" .. invSkin.skin
    local data

    if invSkin.weapon == "knife" then
        dataKey = "knife_" .. dataKey
    end

    data = store:GetAsync(dataKey)

    if not data or not data[invSkin.uuid] then
        return
    end

    data[invSkin.uuid] = nil
    store:SetAsync(dataKey, data)
    print("Successfully removed skin from the database.")
end

return SkinsDB