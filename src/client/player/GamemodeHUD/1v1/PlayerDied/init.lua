local gui = script:WaitForChild("Gui")

local PlayerDied = {}

function PlayerDied.init()
    local self = setmetatable({}, {__index = PlayerDied})
    local player = game.Players.LocalPlayer
    local guiClone = gui:Clone()

    guiClone.Parent = player.PlayerGui
end

return PlayerDied