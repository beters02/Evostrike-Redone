local Players = game:GetService("Players")
Players.PlayerAdded:Connect(function(player)

    -- Add Main Menu UI
    script.Parent:WaitForChild("MainMenu"):Clone().Parent = player.PlayerGui

    -- Patch notes!
    pcall(function() -- get rid of that annoying ass error
        player.PlayerGui:WaitForChild("MainMenu"):WaitForChild("HomeFrame"):WaitForChild("PatchFrame").InformationFrame.TextLabel.Text = require(script.Parent:WaitForChild("patchNotes"))()
    end)
end)