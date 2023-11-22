--[[ NEW, SAFER WAY TO DISTRIBUTE GUIS FROM THE SERVER

Copy this script and put it on the Character, Backpack or PlayerGui
Listen for remotes or whatever, call a Cleanup remote if necessary, destroy the script when ready
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local framework = require(game.ReplicatedStorage.Framework)
local uistate = require(framework.Module.m_states).State("UI")
local gui = script:WaitForChild("Gui")
local mainFrame = gui:WaitForChild("MainFrame")
local loadoutButton = mainFrame:WaitForChild("LoadoutButton")
local respawnButton = mainFrame:WaitForChild("RespawnButton")
local remoteEvent = script:WaitForChild("Events"):WaitForChild("RemoteEvent")
local buyMenu = game.Players.LocalPlayer.PlayerGui:WaitForChild("BuyMenu")

local inLoadout = false
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
    uistate:removeOpenUI("SpawnMenu")
	buyMenu.Enabled = false
    gui:Destroy()
end

function Click.Back()
    canPressDebounce()
    inLoadout = false
    buyMenu.Enabled = false
    uistate:removeOpenUI("BuyMenu")
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
    uistate:addOpenUI("SpawnMenu", gui, true)
end

connect()
start()