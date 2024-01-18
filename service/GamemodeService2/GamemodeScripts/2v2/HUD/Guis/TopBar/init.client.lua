local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Images")
local botAvatar = Images:WaitForChild("BotAvatar")
local GamemodeEvents = ReplicatedStorage:WaitForChild("GamemodeEvents")

function get_player(plrName)
    local success, result = pcall(function()
        return Players[plrName]
    end)
    if success then
        return result
    end
    return false
end

function get_player_avatar(plr: Player | "Bot") -- {avatarId = imgId, name = string}
    if type(plr) == "string" then
        return botAvatar.Image
    end
    return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end

function get_player_name(plr: Player | "Bot")
    if type(plr) == "string" then
        return "Bot"
    end
    return plr.Name
end

local hud = Players.LocalPlayer.PlayerGui:WaitForChild("Container_2v2"):WaitForChild("HUD_2v2")
local team, yourTeamNames, enemyTeamNames = hud:WaitForChild("Events"):WaitForChild("START").Event:Wait()

local teammate = get_player(yourTeamNames[1]) or "Bot"
local enemy1 = get_player(enemyTeamNames[1]) or "Bot"
local enemy2 = get_player(enemyTeamNames[2]) or "Bot"

local gui = script:WaitForChild("Gui")
local mainFrame = gui:WaitForChild("MainFrame")

local infoFrameData = {
    you = {fr = mainFrame:WaitForChild("YourInfoFrame"), plr = Players.LocalPlayer},
    teammate = {fr = mainFrame:WaitForChild("TeammateInfoFrame"), plr = teammate},
    enemy1 = {fr = mainFrame:WaitForChild("Enemy1InfoFrame"), plr = enemy1},
    enemy2 = {fr = mainFrame:WaitForChild("Enemy2InfoFrame"), plr = enemy2}
}

for _, frameData in pairs(infoFrameData) do
    frameData.fr.ImageLabel.Image = get_player_avatar(frameData.plr)
    frameData.fr.TextLabel.Text = get_player_name(frameData.plr)
end

--gui.Name = "2v2_TopBar"
--gui.Parent = Players.LocalPlayer.PlayerGui

print('Added TopBar!')