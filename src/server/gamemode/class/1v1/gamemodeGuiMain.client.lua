local RunService = game:GetService("RunService")
local gui = script.Parent
local remote = gui:WaitForChild("RemoteEvent")
local enemy = gui:WaitForChild("EnemyObject").Value

local mainFrame = gui:WaitForChild("MainFrame")
local timerLabel = mainFrame:WaitForChild("TimerFrame"):WaitForChild("TextLabel")

local yourScoreLabel = mainFrame.ScoreFrame.YourScore
local enemyScoreLabel = mainFrame.ScoreFrame.EnemyScore

local timer = false

local function convertSecToMin(sec: number)
    return tostring(math.floor(sec/60)) .. ": " .. tostring(sec % 60)
end

mainFrame.YourFrame.TextLabel.Text = tostring(game:GetService("Players").LocalPlayer.Name)
mainFrame.EnemyFrame.TextLabel.Text = tostring(enemy.Name)

remote.OnClientEvent:Connect(function(action, ...)

    if action == "UpdateScore" then
        local yours, enemys = ...
        yourScoreLabel.Text = tostring(yours)
        enemyScoreLabel.Text = tostring(enemys)
    elseif action == "StartTimer" then

        if timer then
            timer:Disconnect()
        end

        local endt = tick() + ...
        timer = RunService.RenderStepped:Connect(function()
            timerLabel.Text = convertSecToMin(math.floor(endt - tick()))
        end)

    elseif action == "StopTimer" then
        if timer then
            timer:Disconnect()
            timer = nil
        end
    end

end)