local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamemodeHUDEvents = ReplicatedStorage.GamemodeEvents.HUD

-- Gamemode HUD Modules require an Init and an Enable

-- Current Gamemode HUD Module
local connections = {}
local gamemodeModule = false

local function gmcall(fin, ...)
    local var = table.pack(...)
    pcall(function()
        gamemodeModule[fin](table.unpack(var))
    end)
end

function connect()
    disconnect()
    connections = {
        GamemodeHUDEvents:WaitForChild("INIT").OnClientEvent:Connect(function(gamemode)
            if gamemodeModule then
                gamemodeModule.Disable()
            end
        
            gamemodeModule = require(script[gamemode])
            gamemodeModule.Init()
        end),
        
        
        GamemodeHUDEvents:WaitForChild("START").OnClientEvent:Connect(function(...)
            gamemodeModule.Enable(...)
        end),
        
        
        GamemodeHUDEvents:WaitForChild("StartTimer").OnClientEvent:Connect(function(length)
            gmcall("StartTimer", length)
        end),
        
        
        GamemodeHUDEvents:WaitForChild("ChangeScore").OnClientEvent:Connect(function(data)
            gmcall("ChangeScore", data)
        end),
        
        
        GamemodeHUDEvents:WaitForChild("ChangeRound").OnClientEvent:Connect(function(round)
            gmcall("ChangeRound", round)
        end),
        
        GamemodeHUDEvents:WaitForChild("RoundOver").OnClientEvent:Connect(function(...)
            gmcall("RoundOver", ...)
        end),
        
        GamemodeHUDEvents:WaitForChild("StartRound").OnClientEvent:Connect(function(...)
            gmcall("RoundStart", ...)
        end)
    }
end

function disconnect()
    for _, v in pairs(connections) do
        v:Disconnect()
    end
    connections = {}
end

GamemodeHUDEvents:WaitForChild("EnableBind").Event:Connect(function(enable)
    if enable == nil then
        enable = true
    end
    if enable then
        connect()
    else
        disconnect()
    end
end)