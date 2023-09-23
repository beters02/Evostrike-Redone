local MessagingService = game:GetService("MessagingService")
local Gamemode = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("GamemodeService"))

MessagingService:SubscribeAsync("GetServerInfo", function()
    MessagingService:PublishAsync("GetServerInfoResult", {
        placeid = game.PlaceId,
        jobid = game.JobId,
        gamemode = Gamemode.Gamemode.Name,
        totalPlayers = Gamemode.GetTotalPlayerCount and Gamemode.GetTotalPlayerCount() or {}
    })
end)