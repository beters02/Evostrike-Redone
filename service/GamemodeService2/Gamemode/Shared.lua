local Players = game:GetService("Players")
-- Shared between GamemodeModule and GamemodeClass

local Shared = {}

function Shared.AddUI(player: Player, ui: Instance)
    ui.Parent = player.PlayerGui:WaitForChild("GAMEMODESERVICE_GAMEMODE_UI")
end

function Shared.RemoveUI(player: Player, uiStr: string)
    local ui = player.PlayerGui:WaitForChild("GAMEMODESERVICE_GAMEMODE_UI"):FindFirstChild(uiStr)
    if ui then
        ui:Destroy()
    end
end

function Shared.ClearUI(player: Player)
    player.PlayerGui:WaitForChild("GAMEMODESERVICE_GAMEMODE_UI"):ClearAllChildren()
end

function Shared.ClearAllPlayersUI()
    for i, v in pairs(Players:GetPlayers()) do
        local container = v.PlayerGui:FindFirstChild("GAMEMODESERVICE_GAMEMODE_UI")
        if container then
            container:ClearAllChildren()
        end
    end
end

return Shared