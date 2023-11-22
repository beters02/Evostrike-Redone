local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Bridge = Framework.Service.GamemodeService2.Bridge

Bridge.OnClientEvent:Connect(function(action, var)
    if action == "ChangeMenuType" then
        require(game.Players.LocalPlayer.PlayerScripts.MainMenu).setMenuType(var)
    end
end)