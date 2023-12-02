local gui = script:WaitForChild("Gui")

local PlayerDied = {}
PlayerDied.__index = PlayerDied

function PlayerDied.init()
    local self = setmetatable({}, PlayerDied)
    local player = game.Players.LocalPlayer
    local guiClone = gui:Clone()

    guiClone.Parent = player.PlayerGui
end

return PlayerDied