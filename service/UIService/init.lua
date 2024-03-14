-- Test way to unify UIs through out the game.

export type UIState = "Active" | "Inactive"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Remotes = script:WaitForChild("Remotes")

local UIService = {
    CurrentUI = false,
    CurrentUIState = "Inactive" :: UIState
}

function UIService:GetCurrentModule()
    if RunService:IsClient() then
        return Remotes.RemoteFunction:InvokeServer("GetCurrentModule")
    end
    return {CurrentUI = self.CurrentUI, CurrentUIState = self.CurrentUIState}
end

function UIService:SetCurrentUI(ui: string)
    self.CurrentUI = ui
    if RunService:IsServer() then
        Remotes.RemoteEvent:FireAllClients("SetCurrentUI", ui)
    end
end

function UIService:SetCurrentUIState(uiState: string)
    self.CurrentUIState = uiState
    if RunService:IsServer() then
        Remotes.RemoteEvent:FireAllClients("SetCurrentUIState", uiState)
    end
end

-- Script
if RunService:IsClient() then
    Remotes.RemoteEvent.OnClientEvent:Connect(function(action, ...)
        UIService[action](UIService, ...)
    end)
    local moduleData = UIService:GetCurrentModule()
    UIService.CurrentUI = moduleData.CurrentUI
    UIService.CurrentUIState = moduleData.CurrentUIState
elseif RunService:IsServer() then
    Remotes.RemoteFunction.OnServerInvoke = function(_, action, ...)
        return UIService[action](UIService, ...)
    end
    Players.PlayerAdded:Connect(function(player)
        -- Init UIService UI Container
        local container = Instance.new("ScreenGui")
        container.Name = "UIServiceContainer"
        container.IgnoreGuiInset = true
        container.ResetOnSpawn = false
        container.Parent = player.PlayerGui
    end)
end

return UIService