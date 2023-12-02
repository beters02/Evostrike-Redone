local DataStoreService = game:GetService("DataStoreService")

export type DatabaseSkin = {
    Seed: number, -- 1 -> 100
    Wear: number,  -- 0.0001 -> 0.9999,
    Stickers: {first: string?, second: string?, third: string?, fourth: string?}
}

local SkinsDB = {}

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