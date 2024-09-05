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

--model_skin
--knife_model_skin
export type SkinDataKey = string

export type SeedModifier = (seed: number, model: Model) -> ()

local function SapphireModifier(seed: number, model: Model)
    -- get random hue in rage from 88 -> 240 based on seed (dark blue -> green)
    local r = Random.new(seed)
    local hue = r:NextInteger(88, 240)

    print('Applying seed! Seed: ' .. seed .. " Hue: " .. hue)
    
    local clientsa = model:WaitForChild("Blade"):WaitForChild("SurfaceAppearance")
    local serversa = model:WaitForChild("Server"):WaitForChild("Blade"):WaitForChild("SurfaceAppearance")

    -- apply new color to surface appearance
    clientsa.Color = Color3.fromHSV(hue, 255, 255)
    serversa.Color = Color3.fromHSV(hue, 255, 255)
end

-- For right now we can do it like this,
-- but in the future we will want to apply the same modifier
-- to multiple knives without needing a bunch of extra code
local SeedModifiers: {[SkinDataKey]: SeedModifier} = {
    knife_karambit_sapphire = SapphireModifier,
    knife_m9bayonet_sapphire = SapphireModifier
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
            Stickers = {first = false, second = false, third = false, fourth = false},
        }:: DatabaseSkin
        print("Succesfully added skin to the database.")
    end

    if changed then
        store:SetAsync(dataKey, data)
    end

    return data[invSkin.uuid]
end

function SkinsDB:ApplySkinSeedModifiers(invSkin: string, seed: number, model: Model)
    local dataKey = invSkin.model .. "_" .. invSkin.skin
    if invSkin.weapon == "knife" then
        dataKey = "knife_" .. dataKey
    end

    if SeedModifiers[dataKey] then
        SeedModifiers[dataKey](seed, model)
    end
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