--[[ NEW, SAFER WAY TO DISTRIBUTE GUIS FROM THE SERVER

Copy this script and put it on the Character, Backpack or PlayerGui
Listen for remotes or whatever, call a Cleanup remote if necessary, destroy the script when ready
]]

--[[ CONFIGURATION ]]
local fadeInTime = 2

-- [[ SERVICES ]]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- [[ VARIABLES ]]
local player = game.Players.LocalPlayer
local framework = require(game.ReplicatedStorage.Framework)
local uistate = require(framework.Module.States):Get("UI")
local gui = script:WaitForChild("Gui")
local loadoutButton = gui:WaitForChild("LoadoutButton")
local respawnButton = gui:WaitForChild("RespawnButton")
local killedLabel = gui:WaitForChild("KilledLabel")
local buyMenu
local buyMenuModule
local playerSpawnEvent = framework.Service.GameService.Remotes.PlayerSpawn

local respawned = false

local Debugger = require(framework.Module.Debugger)

loadoutButton.Modal = false
respawnButton.Modal = false

local inLoadout = false
local connections = {}
local canpress = true
local tweens = {}
local camera = workspace.CurrentCamera

local uiCont

--[[ UTILITY FUNC ]]

local function processClickDebounce()
    canpress = false
	task.delay(0.4, function() canpress = true end)
end

--[[ BUTTON AND KEY FUNC ]]

function clickLoadout()
	if inLoadout or not canpress then
		return
	end
	processClickDebounce()
	inLoadout = true
	require(buyMenuModule):Open()
    uistate:addOpenUI("BuyMenu", buyMenu, true)
end

local function clickRespawn()
	if respawned or not canpress then
		print('attempting respawn during incorrect time...')
		return
	end
	processClickDebounce()
	require(buyMenuModule):Close()
	camera.CameraType = Enum.CameraType.Custom
	finish()
	playerSpawnEvent:FireServer()
	respawned = true
end

local function clickBack()
	if not canpress then
		return
	end
	processClickDebounce()
	inLoadout = false
    require(buyMenuModule):Close()
    uistate:removeOpenUI("BuyMenu")
end

local function backKeyPressed()
	if inLoadout then
		clickBack()
		return
	end

	clickLoadout()
end

--[[ GUI FUNC ]]

local function playGuiAnimation()
	for i, v in pairs(tweens) do
		v:Play()
	end
end

function setKilledString()
	killedLabel.Visible = false
	respawnButton.Text = "Spawn"
end

-- [[ EVENT FUNC ]]

function inputBegan(input, gp)
	if gp or not canpress then
		return
	end

	if input.KeyCode == Enum.KeyCode.B then
		backKeyPressed()
	elseif input.KeyCode == Enum.KeyCode.Space then
		clickRespawn()
	end
end

--[[ CORE FUNC ]]

function init()
	setKilledString()

	-- equalize key text size
	--gui.RespawnKeyLabel.Size = gui.BuyMenuKeyLabel.Size

	-- animations
	local ti = TweenInfo.new(fadeInTime)
	for _, v in pairs(gui:GetChildren()) do
		local bgt = v.BackgroundTransparency
		local txt = v.TextTransparency
		v.BackgroundTransparency = 1
		v.TextTransparency = 1

		if v:IsA("TextButton") then
			txt = v.TextLabel.TextTransparency
			v.TextLabel.TextTransparency = 1
			table.insert(tweens, TweenService:Create(v.TextLabel, ti, {TextTransparency = txt}))
			table.insert(tweens, TweenService:Create(v, ti, {BackgroundTransparency = bgt}))
		else
			table.insert(tweens, TweenService:Create(v, ti, {BackgroundTransparency = bgt, TextTransparency = txt}))
		end
	end
end

function connect()
	Debugger:PrepareTableConnect(connections, "InitialPlayerSpawn")
	disconnect()
	table.insert(connections, loadoutButton.MouseButton1Click:Connect(clickLoadout))
    table.insert(connections, respawnButton.MouseButton1Click:Connect(clickRespawn))
	table.insert(connections, UserInputService.InputBegan:Connect(inputBegan))
end

function disconnect()
	for _, v in pairs(connections) do
		v:Disconnect()
	end
	connections = {}
end

function finish()
	loadoutButton.Modal = false
	respawnButton.Modal = false
	uistate:removeOpenUI("BuyMenu")
    uistate:removeOpenUI("SpawnMenu")
    disconnect()
	gui.Enabled = false

	-- UI Modal Fix lol
	for i, v in pairs(uiCont:GetDescendants()) do
		if v:IsA("ImageButton") or v:IsA("TextButton") then
			if v.Modal then
				v.Modal = false
			end
		end
	end

	task.wait()
	task.wait()
end

function start(uiContainer)
	loadoutButton.Modal = true
	respawnButton.Modal = true
	playGuiAnimation()
	camera.CFrame = gui:GetAttribute("StartCF")
	gui.Enabled = true
    uistate:addOpenUI("SpawnMenu", gui, true)
end

local PlayerSpawn = {}

function PlayerSpawn:SetStartCameraCF(uiContainer, cf)
	gui:SetAttribute("StartCF", cf)
end

function PlayerSpawn:Enable(uiContainer)
	if not buyMenu then
		buyMenu = uiContainer:WaitForChild("BuyMenuScript"):WaitForChild("BuyMenu")
	end
	if not buyMenuModule then
        buyMenuModule = uiContainer:WaitForChild("BuyMenuScript")
    end
	
	uiCont = uiContainer

    init()
    connect()
    start(uiContainer)
end

return PlayerSpawn