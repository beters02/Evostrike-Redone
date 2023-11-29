-- [[ CONFIGURATION ]]
local INITIAL_BLACK_SCREEN_LENGTH = 2.5
local SECOND_BLACK_SCREEN_LENGTH = 5
local HUD_ENABLE_DELAY = 1
local SCRIPT_DESTRUCTION_DELAY = 3

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local PlayerLoadedEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("playerLoadedEvent")
local Services = ReplicatedStorage:WaitForChild("Services")
local Promise = require(script:WaitForChild("c_promise"))

ReplicatedFirst:RemoveDefaultLoadingScreen()

local gui = script:WaitForChild("LoadingGUI")
local player = Players.LocalPlayer
local hud: ScreenGui = player.PlayerGui:FindFirstChild("HUD")
if hud then hud.Enabled = false end

local map = workspace:WaitForChild("Map")
local intro = script:WaitForChild("Intro")

local loading = true
local isPlayingIntro = false
local forceStop = false
local hudconn = false

local tweens = {}
tweens._in = TweenService:Create(gui:WaitForChild("BlackFrame"), TweenInfo.new(2), {BackgroundTransparency = 1})
tweens._out1 = TweenService:Create(gui.BlackFrame, TweenInfo.new(1.5), {BackgroundTransparency = 0})
tweens._out2 = TweenService:Create(gui.BlackFrame, TweenInfo.new(2.5), {BackgroundTransparency = 1})

local decToLoad = {
    Services:WaitForChild("WeaponService"):WaitForChild("Weapon"),
    Services:WaitForChild("AbilityService"):WaitForChild("Ability"),
    game:GetService("MaterialService")
}

function init()
    -- connect
end

function start()
    
end

function main()
    task.wait(INITIAL_BLACK_SCREEN_LENGTH)
	tweens._in:Play()
    Promise.fromEvent(tweens._in.Completed):andThen()
end

local function get_hud()
    return player.PlayerGui:FindFirstChild("HUD") or false
end

local function enable_hud(enable: boolean)
    if player.PlayerGui:FindFirstChild("HUD") then
        player.PlayerGui.HUD.Enabled = enable
    end
end

local function connect_hud_disable(connect: boolean)
    local _hud = get_hud()
    if not _hud then return end
    if connect then
        hudconn = hud:GetPropertyChangedSignal("Enabled"):Connect(function()
            if hud.Enabled then
                hud.Enabled = false
            end
        end)
    else
        hudconn:Disconnect()
    end
end

local function intro_animation()
    isPlayingIntro = true
	task.wait(INITIAL_BLACK_SCREEN_LENGTH)
	tweens._in:Play()
	tweens._in.Completed:Wait()
	task.wait(SECOND_BLACK_SCREEN_LENGTH)
	tweens._out1:Play()
	tweens._out1.Completed:Wait()
	gui.MainFrame.Frame.Visible = false
	gui.IntroFrame.Visible = false
    if loading then
        tweens._in:Play()
        tweens._in.Completed:Wait()
    end
    isPlayingIntro = false
end

local function intro_finished_animation()
    local wasLoading = loading
    for _, tween in pairs(tweens) do
        if tween.PlaybackState == Enum.PlaybackState.Playing then
            tween:Pause()
        end
    end

    if wasLoading then
        tweens._out1:Play()
        tweens._out1.Completed:Wait()
    end
    gui.MainFrame.Visible = false
    gui.TeamFrame.Visible = false
    gui.IntroFrame.Visible = false
	tweens._out2:Play()
    tweens._out2.Completed:Once(function()
        gui:Destroy()
    end)
	Debris:AddItem(script, 5)
end

local function intro_bypass()
    loading = false
    isPlayingIntro = false
    forceStop = true
    FINISH(true)
end

local function intro_verify_bypass_input(input)
    if not input.KeyCode then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Minus) and UserInputService:IsKeyDown(Enum.KeyCode.Equals) then
        intro_bypass()
    end
end

function INIT()

    --prepare loading screen
    gui.MainFrame.LoadingText.Text = "Loading Map..."
    gui.Parent = Players.LocalPlayer.PlayerGui -- give player gui

    -- preare intro screen
    intro:Play() -- play intro music
    gui.IntroFrame.Visible = true
    gui.BlackFrame.Visible = true
    gui.MainFrame.Visible = true
    gui.BlackFrame.BackgroundTransparency = 0
    gui.TeamFrame.Visible = false

    -- preload Loading GUI
    print("loading loading screen")
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("ImageLabel") then
            ContentProvider:PreloadAsync({v})
        end
    end
end

function CONNECT()
    UserInputService.InputBegan:Connect(intro_verify_bypass_input)
    enable_hud(false)
    connect_hud_disable(true)
end

function START()
    -- start intro
    task.spawn(intro_animation)

    -- load map
    local mapChildren = map:GetChildren()
    while loading do
        print('loading map assets')
        local count = #mapChildren
        gui.MainFrame.LoadingText.Text = "Loading Map: 0" .. "/" .. tostring(count)
        for i = 1, count do
            gui.MainFrame.LoadingText.Text = "Loading Map: " .. tostring(i) .. "/" .. tostring(count)
            ContentProvider:PreloadAsync({mapChildren[i]})
        end
    
        -- load game assets
        print('loading game assets')
        gui.MainFrame.LoadingText.Text = "Loading Game Assets... "
        for _, parent in pairs(decToLoad) do
            ContentProvider:PreloadAsync(parent:GetDescendants())
        end
        
        loading = false
    end
end

function FINISH(bypass)
    if not bypass then
        if forceStop then
            return
        end
        if isPlayingIntro or loading then
            repeat task.wait() until not isPlayingIntro and not loading
        end
    end
    
    PlayerLoadedEvent:FireServer()
    intro_finished_animation()
    intro:Stop()
    
    task.delay(HUD_ENABLE_DELAY, function()
        if player.PlayerGui:FindFirstChild("HUD") then
            player.PlayerGui.HUD.Enabled = true
        end
    end)
    
    Debris:AddItem(script, SCRIPT_DESTRUCTION_DELAY)
end

--@run
INIT()
CONNECT()
START()
FINISH()