--[[ NEW, SAFER WAY TO DISTRIBUTE GUIS FROM THE SERVER

Copy this script and put it on the Character, Backpack or PlayerGui
Listen for remotes or whatever, call a Cleanup remote if necessary, destroy the script when ready
]]

local st = tick()

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local UIState = require(Framework.Module.States):Get("UI")

local localPlayer = Players.LocalPlayer
local gui = script:WaitForChild("Gui")
local remoteEvent = script:WaitForChild("Events"):WaitForChild("RemoteEvent")
local remoteFunction = script:WaitForChild("Events"):WaitForChild("RemoteFunction")
local timer = false

local timerLabel = gui:WaitForChild("NextGameTimerLabel")
local nextMapLabel = gui:WaitForChild("NextMapLabel")

local _lfr = gui:WaitForChild("LeaderboardFrame")
local leaderboard = {itemFrame = _lfr:WaitForChild("ItemFrame")}

local _efr = gui:WaitForChild("EarnedFrame")
local earned = {premiumCreditsLabel = _efr:WaitForChild("PremiumCredits"), strafeCoinsLabel = _efr:WaitForChild("StrafeCoins"), xpLabel = _efr:WaitForChild("XP")}

local timerLength = script:GetAttribute("TimerLength") or 15
local earnedSC = script:GetAttribute("EarnedStrafeCoins") or 0
local earnedPC = script:GetAttribute("EarnedPremiumCredits") or 0
local earnedXP = script:GetAttribute("EarnedXP") or 0
local newMapStr = script:GetAttribute("NewMapStr") or "Kicking players..."

local leaderboardStart = 3

local hudModule = require(localPlayer.PlayerScripts.HUD)

--[[ Utility ]]
local function convertSecToMin(sec: number)
    local _sec = sec % 60
    if _sec < 10 then
        _sec = "0"..tostring(_sec)
    end
	return tostring(math.floor(sec/60)) .. ": " .. tostring(_sec)
end

function sortPlayer(sorted, count, plrname, plrdata)
    for si, sv in pairs(sorted) do
        if plrdata.Kills > sv[2].Kills then
            table.insert(sorted, si, {plrname, plrdata})
            return
        end
    end
    table.insert(sorted, count + 1, {plrname, plrdata})
end

function leaderboardCreateItemFrame(plrname, plrdata, count)
    local itemFrame = leaderboard.itemFrame:Clone()
    itemFrame.Name = tostring(count) .. "_" .. tostring(plrname)
    itemFrame:WaitForChild("KillsLabel").Text = tostring(plrdata.Kills)
    itemFrame:WaitForChild("DeathsLabel").Text = tostring(plrdata.Deaths)
    itemFrame:WaitForChild("NameLabel").Text = tostring(plrname)
    itemFrame.Visible = true
end

function initLeaderboard(playerData)
    local sorted = {}
    local count = 0
    for plrname, plrdata in ipairs(playerData) do
        if count == 0 then
            table.insert(sorted, {plrname, plrdata})
        else
            sortPlayer(sorted, count, plrname, plrdata)
        end
        count += 1
    end
    count = leaderboardStart + 1
    for _, v in ipairs(sorted) do
        leaderboardCreateItemFrame(v[1], v[2], v[1] == localPlayer.Name and leaderboardStart or count)
        count += 1
    end
end

function finish()
    -- out tweens?
    gui:Destroy()
    UIState:removeOpenUI("DeathmatchRoundOver")
    return true
end

-- [[ Main ]]
function init()
    earned.premiumCreditsLabel.Text = tostring(earnedPC)
    earned.strafeCoinsLabel.Text = tostring(earnedSC)
    earned.xpLabel.Text = tostring(earnedXP) .. " XP"
    timer = true
    if string.match(newMapStr, "Kicking") then
        nextMapLabel.Visible = false
        timerLabel.Text = "Kicking players..."
    else
        nextMapLabel.Text = "Next map: " .. newMapStr
        timer = true
    end
end

function connect()
    remoteEvent.OnClientEvent:Once(function(playerData)
        initLeaderboard(playerData)
    end)
    
    if timer then
        local endt = st + timerLength
        timer = RunService.RenderStepped:Connect(function()
            timerLabel.Text = convertSecToMin(math.floor(endt - tick()))
            if tick() >= endt then
                hudModule:Enable()
                Debris:AddItem(gui, 3)
                timer:Disconnect()
            end
        end)
    end
    
    remoteFunction.OnClientInvoke = finish
end

function start()
    hudModule:Disable()
    gui.Parent = localPlayer.PlayerGui
    UIState:addOpenUI("DeathmatchRoundOver", gui, true)
    task.delay(timerLength - 1, function()
        UIState:removeOpenUI("DeathmatchRoundOver")
    end)
end

init()
connect()
start()