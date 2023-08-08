local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))

-- [[ INVENTORY ]]
local function playerAdded_initInventory(player)
    Framework.Weapon.Module.StoredPlayerInventories[player.Name] = {primary = nil, secondary = nil, ternary = nil}
end

local function playerRemoving_destroyInventory(player)
    Framework.Weapon.Module.StoredPlayerInventories[player.Name] = nil
end

--[[ PLAYER ]]
function defaultCharAdded(player, char)
end

function defaultHumDied(player, char, hum)
    
end

-- [[ CONNECT ]]
Players.PlayerAdded:Connect(function(plr)
    -- inventory
    playerAdded_initInventory(plr)

    -- char, died
    plr.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid")
        defaultCharAdded(plr, char)

        hum.Died:Once(function()
            defaultHumDied(plr, char, hum)
        end)
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    playerRemoving_destroyInventory(plr)
end)