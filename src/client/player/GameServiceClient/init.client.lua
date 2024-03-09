local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GameServiceRemotes = Framework.Service.GameService.Remotes
local GameHUD = script:WaitForChild("GameHUD")

local player = game.Players.LocalPlayer
local currUIContainer

local function getGamemodeHUD(gamemodeStr)
    return GameHUD:FindFirstChild(gamemodeStr)
end

local function getUIModule(moduleStr)
    return currUIContainer:FindFirstChild(moduleStr)
end

-- Creates a Gamemode UI Container with all needed UI elements for the gamemode.
GameServiceRemotes.SetUIGamemode.OnClientEvent:Connect(function(gamemode)
    if currUIContainer then
        currUIContainer:Destroy()
    end

    currUIContainer = Instance.new("ScreenGui")
    currUIContainer.ResetOnSpawn = false
    currUIContainer.IgnoreGuiInset = true
    currUIContainer.Name = "GAME_SERVICE_UI_CONTAINER"
    currUIContainer.Enabled = true
    currUIContainer.Parent = game.Players.LocalPlayer.PlayerGui

    for _, uiModule in pairs(getGamemodeHUD(gamemode):GetChildren()) do
        local c = uiModule:Clone()
        c.Parent = currUIContainer
        for _, ui in pairs(c:GetChildren()) do
            if ui:IsA("ScreenGui") then
                ui.Enabled = false
            end
        end
    end
end)

-- Calls a UI Module Function
GameServiceRemotes.CallUIFunction.OnClientEvent:Connect(function(ui: string, func: string, ...: any)
    local module = getUIModule(ui)
    if not module then
        warn("Could not find UI " .. ui)
        return
    end

    local req = require(module)
    req[func](req, currUIContainer, ...)
end)