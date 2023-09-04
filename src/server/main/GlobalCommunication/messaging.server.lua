local MessagingService = game:GetService("MessagingService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Gamemode = require(Framework.sm_gamemode.Location)

MessagingService:SubscribeAsync("GetServerInfo", function()
    MessagingService:PublishAsync("GetServerInfoResult", {
        placeid = game.PlaceId,
        jobid = game.JobId,
        gamemode = Gamemode.currentGamemode,
        totalPlayers = Gamemode.GetTotalPlayerCount and Gamemode.GetTotalPlayerCount() or {}
    })
end)