-- Request skin seeds from our server.


--[[ Assets API Key M7QGzlp0g06ZTW677T/ynVrREcutjSarIaCjFtxs0ZApseyf ]]

-- 1-100
--[[type Seed = number

local SeedService = {}
local HttpService = game:GetService("HttpService")
function SeedService:GetSeed(weapon: string, skin: string, seed: Seed)
    local uri = "http://i.imgur.com/Rg5Qpqu.jpeg"
    local response = HttpService:RequestAsync({
        ["Method"] = "POST",
        ["Url"] = "http://172.23.1.92:2185/api/roblox-images/upload",
        ["Headers"] = {
            ["Content-Type"] = "application/json"
        },
        ["Body"] = HttpService:JSONEncode({
            ["weapon"] = weapon,
			["skin"] = skin,
			["seed"] = seed
        })
    })

    print(response)
end

SeedService:GetSeed("karambit", "fractal", 1)

return SeedService]]

return nil