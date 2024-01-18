--[[ NEW, SAFER WAY TO DISTRIBUTE GUIS FROM THE SERVER

Copy this script and put it on the Character, Backpack or PlayerGui
Listen for remotes or whatever, call a Cleanup remote if necessary, destroy the script when ready
]]

--[[ CONFIGURATION ]]
local fadeInTime = 2

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local framework = require(game.ReplicatedStorage.Framework)
local uistate = require(framework.Module.States):Get("UI")
local gui = script:WaitForChild("Gui")
local mainFrame = gui:WaitForChild("MainFrame")
local loadoutButton = mainFrame:WaitForChild("LoadoutButton")
local respawnButton = mainFrame:WaitForChild("RespawnButton")
local killedLabel = mainFrame:WaitForChild("KilledLabel")
local remoteEvent = script:WaitForChild("Events"):WaitForChild("RemoteEvent")
local buyMenu = game.Players.LocalPlayer.PlayerGui:WaitForChild("BuyMenu")
local killstr = script:GetAttribute("KilledString") or "You died!"
local player = game.Players.LocalPlayer
local killer = script:WaitForChild("KillerObject", 3)
killer = killer and killer.Value or player
local camera = workspace.CurrentCamera

local lastGoodCF = CFrame.new()
local primcf = CFrame.new()
local success = false

local inLoadout = false
local inTween = false
local connections = {}
local canpress = true

--[[UTILITY]]
local function canPressDebounce()
    canpress = false
	task.delay(0.4, function() canpress = true end)
end

--[[BUTTON CLICK FUNC]]
local Click = {}

function Click.Loadout()
    canPressDebounce()
	inLoadout = true
	buyMenu.Enabled = true
    uistate:addOpenUI("BuyMenu", buyMenu, true)
end

function Click.Respawn()
    canPressDebounce()
	disconnect()
	remoteEvent:FireServer("Respawn")
    uistate:removeOpenUI("BuyMenu")
    uistate:removeOpenUI("DeathMenu")
	buyMenu.Enabled = false
    gui:Destroy()
end

function Click.Back()
    canPressDebounce()
    inLoadout = false
    buyMenu.Enabled = false
    uistate:removeOpenUI("BuyMenu")
end

--[[ MAIN ]]

camera.CameraType = Enum.CameraType.Scriptable
local conn
conn = game:GetService("RunService").RenderStepped:Connect(function(dt)
	success, primcf = pcall(function()
		return killer.Character.PrimaryPart.CFrame
	end)
	if not success or not killer.Character or not camera then
		lastGoodCF = camera.CFrame:Lerp(lastGoodCF, dt * 10)
	else
		lastGoodCF = camera.CFrame:Lerp(CFrame.new(primcf.Position + Vector3.new(5, 10, 0) - camera.CFrame.LookVector, primcf.Position), dt * 10)
	end
	camera.CFrame = lastGoodCF
end)

script:WaitForChild("Events"):WaitForChild("Finished").OnClientEvent:Connect(function()
    conn:Disconnect()
	camera.CameraType = Enum.CameraType.Custom
end)

function init()
	mainFrame.GroupTransparency = 1
    inTween = TweenService:Create(mainFrame, TweenInfo.new(fadeInTime, Enum.EasingStyle.Cubic), {GroupTransparency = 0})

	if killstr == "Spawn" then
		killedLabel.Visible = false
		respawnButton.Text = "Spawn"
	else
		killedLabel.Text = tostring(killstr)
	end
end

function connect()
    connections[1] = loadoutButton.MouseButton1Click:Connect(function()
		if inLoadout or not canpress then return end
        inLoadout = true
		canpress = false
		Click.Loadout()
	end)
	connections[2] = respawnButton.MouseButton1Click:Connect(function()
        if not canpress then return end
		Click.Respawn()
	end)
	connections[3] = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if not canpress then return end
		if input.KeyCode == Enum.KeyCode.B then
			if inLoadout then
				inLoadout = false
				canpress = false
				Click.Back()
			else
				inLoadout = true
				canpress = false
				Click.Loadout()
			end
		elseif input.KeyCode == Enum.KeyCode.Space then
			Click.Respawn()
		end
	end)
end

function disconnect()
	for _, v in pairs(connections) do
		v:Disconnect()
	end
	connections = {}
end

function start()
    gui.Parent = Players.LocalPlayer.PlayerGui
    uistate:addOpenUI("DeathMenu", gui, true)
    inTween:Play()
end

init()
connect()
start()