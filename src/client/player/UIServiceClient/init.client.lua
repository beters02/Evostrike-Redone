local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local UIService = require(Framework.Service.UIService)
local UI = script:WaitForChild("UI")

local player = game.Players.LocalPlayer
local container = player.PlayerGui:WaitForChild("UIServiceContainer")

local currentUI = false
local currentUIState = "Inactive"

local function init()
    -- compile all UIs into container
    for _, module in pairs(UI:GetChildren()) do
        for _, moduleChild in pairs(module:GetChildren()) do
            if moduleChild:IsA("ScreenGui") then
                moduleChild.Enabled = false
                for _, uiChild in pairs(moduleChild:GetDescendants()) do
                    pcall(function() if uiChild.Modal then uiChild.Modal = false end end)
                end
            end
        end
    end

    currentUI = UIService.CurrentUI
    currentUIState = UIService.CurrentUIState
    if currentUIState == "Active" then
        activateUI(UIService.CurrentUI)
    end

    -- connect uistate and ui changes
    Framework.Service.UIService.Remotes.RemoteEvent.OnClientEvent:Connect(function(action, ...)
        if action == "SetCurrentUI" then
            deactivateUI()
            currentUI = ...
        elseif action == "SetCurrentUIState" then
            deactivateUI()
            currentUIState = ...
            if currentUIState == "Active" then
                activateUI()
            end
        end
    end)
end

function activateUI(ui: string?)
    if ui then
        currentUI = require(container[ui])
    end
    currentUIState = "Active"
    currentUI:Enable()
end

function deactivateUI()
    if currentUI and currentUI == "Active" then
        currentUI:Disable()
        currentUIState = "Inactive"
    end
end

init()