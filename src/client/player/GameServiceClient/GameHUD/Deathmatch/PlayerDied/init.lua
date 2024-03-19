--[[ NEW, SAFER WAY TO DISTRIBUTE GUIS FROM THE SERVER

Copy this script and put it on the Character, Backpack or PlayerGui
Listen for remotes or whatever, call a Cleanup remote if necessary, destroy the script when ready
]]

--[[ CONFIGURATION ]]
local deathText = "KILLED BY\n_plr"
local fadeInTime = 2
local cameraFollowOffset = Vector3.new(5, 10, 0)
local showDeadPlayerTime = 2
local cameraFollowPlayerLerpSpeed = 10
local cameraSwitchLerpSpeed = 6
local cameraLookAtEnemyLerpSpeed = 10
local zoomEnemyFOV = 50
local zoomEnemySpeed = 1.5
local zoomEnemyTween = false

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- [[ VARIABLES ]]
local player = game.Players.LocalPlayer
local framework = require(game.ReplicatedStorage.Framework)
local playerData = require(framework.Module.PlayerData)
local evoPlayerEvents = framework.Module.EvoPlayer:WaitForChild("Events")
local uistate = require(framework.Module.States):Get("UI")
local hud = require(player.PlayerScripts.HUD)
local gui = script:WaitForChild("Gui")
local loadoutButton = gui:WaitForChild("LoadoutButton")
local respawnButton = gui:WaitForChild("RespawnButton")
local killedLabel = gui:WaitForChild("KilledLabel")
local buyMenu
local buyMenuModule
local killstr = script:GetAttribute("KilledString") or "You died!"
local killer --=script:WaitForChild("KillerObject", 3)
local Math = require(framework.Module.lib.fc_math)
local playerSpawnEvent = framework.Service.GameService.Remotes.PlayerSpawn

loadoutButton.Modal = false
respawnButton.Modal = false

local killerChar = false
local camera = workspace.CurrentCamera

local lastGoodCF = CFrame.new()
local currPlrCF = CFrame.new()
local currCamLerpSpeed = 0
local success = false
local inLoadout = false
local connections = {}
local canpress = true
local updateConn = false
local elapsed = 0
local switchLength = 0
local isShowingDeadPlayer = false
local isSwitchingPlayer = false
local plrKillerDmgInteractions = false
local getCurrCameraLerpCF
local tweens = {}
local defFov = playerData:GetPath("options.camera.FOV")
local enabled = false

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

local respawnButtonEnabled = false
local function clickRespawn()
	if not canpress then
		return
	end
	if not respawnButtonEnabled then
		return
	end
	processClickDebounce()
    require(buyMenuModule):Close()
	finish()
	playerSpawnEvent:FireServer()
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

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local receivedColor = Color3.fromRGB(167, 25, 25)
local gaveColor = Color3.fromRGB(25, 167, 30)
local function preparePlayerDamagePacketsGui()
	local lastTimeStamp = 0
	local counter = #plrKillerDmgInteractions + 1
	for _, v in spairs(plrKillerDmgInteractions, function(t,a,b) return t[b].timeStamp < t[a].timeStamp end) do
		counter -= 1

		local packetFrame = gui.DamageInformation.Packet:Clone()
		packetFrame.Name = tostring(counter) .. "_Packet"
		packetFrame.Visible = true
		packetFrame.Parent = gui.DamageInformation
		
		if lastTimeStamp == 0 then
			packetFrame.TimeLabel.Text = "0:00"
		else
			local timeBetween = lastTimeStamp - v.timeStamp
			if timeBetween > 60 then
				timeBetween = Math.secToMin(timeBetween)
			end
			packetFrame.TimeLabel.Text = tostring(timeBetween)
		end

		lastTimeStamp = v.timeStamp

		if v.interaction == "Given" then
			packetFrame.DamageLabel.TextColor3 = gaveColor
			packetFrame.DamageLabel.Text = "gave " .. tostring(v.damage) .. " damage"
		else
			packetFrame.DamageLabel.TextColor3 = receivedColor
			packetFrame.DamageLabel.Text = "received " .. tostring(v.damage) .. " damage"
		end
	end
end

local function prepareGui()
	setKilledString()
	preparePlayerDamagePacketsGui()

	-- equalize key text size
	gui.RespawnKeyLabel.Size = gui.BuyMenuKeyLabel.Size

	-- animations
	local ti = TweenInfo.new(fadeInTime)
	for _, v in pairs(gui:GetChildren()) do
		local bgt = v.BackgroundTransparency
		v.BackgroundTransparency = 1

		if v:IsA("TextButton") then
			local txt = v.TextLabel.TextTransparency
			v.TextLabel.TextTransparency = 1
			table.insert(tweens, TweenService:Create(v.TextLabel, ti, {TextTransparency = txt}))
			table.insert(tweens, TweenService:Create(v, ti, {BackgroundTransparency = bgt}))
		elseif v:IsA("Frame") then
			table.insert(tweens, TweenService:Create(v, ti, {BackgroundTransparency = bgt}))

			for _, packetFrame in pairs(v:GetChildren()) do
				if not packetFrame:IsA("Frame") or not packetFrame.Visible then
					continue
				end
				for _, packetTextLabel in pairs(packetFrame:GetChildren()) do
					if not packetTextLabel:IsA("TextLabel") then
						continue
					end
					local txt1 = packetTextLabel.TextTransparency
					local bg1 = packetTextLabel.BackgroundTransparency
					table.insert(tweens, TweenService:Create(packetTextLabel, ti, {BackgroundTransparency = bg1, TextTransparency = txt1}))
					packetTextLabel.TextTransparency = 1
					packetTextLabel.BackgroundTransparency = 1
				end
			end
		else
			local txt = v.TextTransparency
			v.TextTransparency = 1
			table.insert(tweens, TweenService:Create(v, ti, {BackgroundTransparency = bgt, TextTransparency = txt}))
		end
	end
end

local function playGuiAnimation()
	for i, v in pairs(tweens) do
		v:Play()
	end
end

function parseDeathText()
	if string.match(deathText, "_plr") then
		return string.gsub(deathText, "_plr", killer.Name)
	end
	return deathText
end

function setKilledString()
	if killstr == "Spawn" then
		killedLabel.Visible = false
		respawnButton.Text = "Spawn"
		return
	end

	killedLabel.Text = parseDeathText()
end

--[[ CAMERA ANIMATIONS FUNC ]]

function initCameraAnimation()
	isShowingDeadPlayer = true
	getCurrCameraLerpCF = followDiedPlayerCF
	currCamLerpSpeed = cameraFollowPlayerLerpSpeed
	zoomEnemyTween = TweenService:Create(camera, TweenInfo.new(zoomEnemySpeed), {FieldOfView = zoomEnemyFOV})
end

-- camera follows died player for a set time,
-- then stays in position while fixing orientation to enemy position.
function processCameraAnimation(dt)
	elapsed += dt

	-- first animation finished, only start second animation if player did not kill self
	if isShowingDeadPlayer and elapsed >= showDeadPlayerTime and killer ~= player then
		elapsed = 0
		isShowingDeadPlayer = false
		isSwitchingPlayer = true

		-- switch animation function
		getCurrCameraLerpCF = followKillerCF

		-- we change lerp speed while switching for smoother animation
		switchLength = calculateLerpTimeToSwitch(dt)
		currCamLerpSpeed = cameraSwitchLerpSpeed

		-- zoom the fov in a bit
		zoomEnemyTween:Play()
	end

	-- change lerp speed back
	if isSwitchingPlayer and elapsed >= switchLength then
		isSwitchingPlayer = false
		currCamLerpSpeed = cameraLookAtEnemyLerpSpeed
	end

	lastGoodCF = getCurrCameraLerpCF(dt)
	camera.CFrame = lastGoodCF
end

-- camera follows dead player
function followDiedPlayerCF(dt)
	-- we either follow the current follow player or go to the last "good" CFrame
	success, currPlrCF = pcall(function()
		return player.Character.PrimaryPart.CFrame
	end)

	local lerpCf = lastGoodCF
	if camera and success and player.Character then
		lerpCf = CFrame.new(currPlrCF.Position + cameraFollowOffset --[[ camera.CFrame.LookVector]], currPlrCF.Position)
	end

	return camera.CFrame:Lerp(lerpCf, dt * currCamLerpSpeed)
end

-- camera stays in position while changing orientation
function followKillerCF(dt)
	success, currPlrCF = pcall(function()
		return killer.Character.PrimaryPart.CFrame
	end)
	
	local lerpCf = lastGoodCF
	if camera and success and killer.Character then
		lerpCf = CFrame.new(camera.CFrame.Position, currPlrCF.Position)
	end

	return camera.CFrame:Lerp(lerpCf, dt * currCamLerpSpeed)
end

function calculateLerpTimeToSwitch(dt)
	local succ, cframes = pcall(function()
		local cframes = {}
		cframes.killer = killer.Character.PrimaryPart.CFrame
		cframes.player = player.Character.PrimaryPart.CFrame
		return cframes
	end)
	if not succ then
		return false
	end

	local distance = cframes.killer.Position - cframes.player.Position
	distance = distance.Magnitude

	return (distance/cameraSwitchLerpSpeed) * dt
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
	local succ
	succ, killerChar = pcall(function()
		return killer.Character
	end)

	if succ then
		task.spawn(function()
			if killer == player then
				local rag = killerChar:WaitForChild("RagdollValue", 1)
				local eh = rag and rag:WaitForChild("EnemyHighlight", 1)
				if eh then
					eh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					eh.Adornee = rag
				end
			else
				local eh = killerChar:WaitForChild("EnemyHighlight", 2)
				if eh then
					eh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				end
			end
		end)
	end

	camera.CameraType = Enum.CameraType.Scriptable

	if Players[killer.Name] then
		plrKillerDmgInteractions = evoPlayerEvents.GetPlayerDamageInteractionsBind:Invoke(killer)
	else
		plrKillerDmgInteractions = false
	end

	prepareGui()
	initCameraAnimation()
end

function update(dt)
	processCameraAnimation(dt)
end

function connect()
	connections[5] = RunService.RenderStepped:Connect(update)
    connections[1] = loadoutButton.MouseButton1Click:Connect(clickLoadout)
	connections[3] = UserInputService.InputBegan:Connect(inputBegan)
end

function disconnect()
	for _, v in pairs(connections) do
		v:Disconnect()
	end
	connections = {}
end

function start()
	hud:Disable()
    uistate:addOpenUI("DeathMenu", gui, true)
    playGuiAnimation()
    gui.Enabled = true
    loadoutButton.Modal = true
    respawnButton.Modal = true
end

function finish()
	if zoomEnemyTween.PlaybackState == Enum.PlaybackState.Playing then
		zoomEnemyTween:Cancel()
	end
	disconnect()
	camera.FieldOfView = defFov
	hud:Enable()
	uistate:removeOpenUI("BuyMenu")
    uistate:removeOpenUI("DeathMenu")
    if player ~= killer and killer.Character then
		killer.Character.EnemyHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	end
	camera.CameraType = Enum.CameraType.Custom
    gui.Enabled = false
    loadoutButton.Modal = false
    respawnButton.Modal = false
	enabled = false
end

local PlayerDied = {}

local started = false

function PlayerDied:Enable(uiContainer, sentKiller, respawnWaitLength)
    killer = sentKiller or player
	respawnButtonEnabled = false

    if not buyMenuModule then
        buyMenuModule = uiContainer:WaitForChild("BuyMenuScript")
    end
    if not buyMenu then
		buyMenu = buyMenuModule:WaitForChild("BuyMenu")
	end

    if not started then
        started = true
    end

	enabled = true

    init()
    connect()
    start()

	if killer == player then
		self:EnableRespawnButton()
		return
	end

	local lastSec = 3
	local timeElapsed = 0
	respawnWaitLength = respawnWaitLength + 0.2

	respawnButton.TextLabel.Text = tostring(lastSec)

	connections[4] = RunService.RenderStepped:Connect(function(dt)
		timeElapsed += dt

		if timeElapsed >= respawnWaitLength then
			self:EnableRespawnButton()
			connections[4]:Disconnect()
			return
		end

		local currLastSec = 3 - math.floor(timeElapsed)
		if lastSec ~= currLastSec then
			lastSec = currLastSec
			respawnButton.TextLabel.Text = tostring(lastSec)
		end
	end)
end

function PlayerDied:EnableRespawnButton()
	respawnButtonEnabled = true
	respawnButton.TextLabel.Text = "RESPAWN"
	connections[2] = respawnButton.MouseButton1Click:Connect(clickRespawn)
end

function PlayerDied:Disable()
	if enabled then
	finish()
		enabled = false
	end
end

return PlayerDied