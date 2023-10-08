-- [[ CONFIGURATION ]]
local INITIAL_BLACK_SCREEN_LENGTH = 2.5
local SECOND_BLACK_SCREEN_LENGTH = 5
local HUD_ENABLE_DELAY = 1
local SCRIPT_DESTRUCTION_DELAY = 3

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
ReplicatedFirst:RemoveDefaultLoadingScreen()
local PlayerLoadedEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("playerLoadedEvent")

local gui = script:WaitForChild("LoadingGUI")
local player = Players.LocalPlayer
local hud: ScreenGui = player.PlayerGui:FindFirstChild("HUD")
if hud then hud.Enabled = false end

local tweens = {}
tweens._in = TweenService:Create(gui:WaitForChild("BlackFrame"), TweenInfo.new(2), {BackgroundTransparency = 1})
tweens._out1 = TweenService:Create(gui.BlackFrame, TweenInfo.new(1.5), {BackgroundTransparency = 0})
tweens._out2 = TweenService:Create(gui.BlackFrame, TweenInfo.new(2.5), {BackgroundTransparency = 1})

local map = workspace:WaitForChild("Map")
local isPlayingIntro = false
local intro = script:WaitForChild("Intro")

local thread = false
local loading = true
local hudconn = false

local preloads = {
    loading = {},
    map = map:GetChildren(),
    assets = {}
}

local preloadsVar = {
    assets = false
}

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
	tweens._in:Play()
	tweens._in.Completed:Wait()
	isPlayingIntro = false
end

local function intro_finished_animation()
    for _, tween in pairs(tweens) do
        if tween.PlaybackState == Enum.PlaybackState.Playing then
            tween:Pause()
        end
    end

    tweens._out1:Play()
	tweens._out1.Completed:Wait()
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
    if gui and loading then
        loading = false
        isPlayingIntro = false

        task.spawn(intro_finished_animation)
        enable_hud(true)
        intro:Stop()
        coroutine.yield(thread)
    end
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
    --preload game assets
    task.spawn(function()
        local preassets = {}
        local assets = {}
        for _, v in pairs(ReplicatedStorage:WaitForChild("Services"):GetDescendants()) do
            if string.match(v.Name, "Assets") then
                table.insert(preassets, v)
            end
        end
        for _, assetFolder in pairs(preassets) do
            for _, catFolder in pairs(assetFolder:GetChildren()) do
                for _, dec in pairs(catFolder:GetChildren()) do
                    if dec:IsA("Animation") or dec:IsA("ImageLabel") or dec:IsA("Sound") then
                        table.insert(assets, dec)
                    elseif dec:IsA("Model") then
                        for _, mdec in pairs(dec:GetDescendants()) do
                            if mdec:IsA("Part") or mdec:IsA("BasePart") or mdec:IsA("MeshPart") or mdec:IsA("Texture") or mdec:IsA("SurfaceAppearance") then
                                table.insert(assets, mdec)
                            end
                        end
                    end
                end
            end
        end
        for _, v in pairs(MaterialService:GetDescendants()) do
            if v:IsA("MaterialVariant") then
                table.insert(assets, v)
            end
        end
        preloads.assets = assets
        preloadsVar.assets = true
    end)
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
    if not loading then return end
    print('loading map assets')
    local count = #preloads.map
    gui.MainFrame.LoadingText.Text = "Loading Map: 0" .. "/" .. tostring(count)
    for i = 1, count do
        if not loading then break end
        gui.MainFrame.LoadingText.Text = "Loading Map: " .. tostring(i) .. "/" .. tostring(count)
        ContentProvider:PreloadAsync({preloads.map[i]})
    end
   
    -- load game assets
    if not loading then return end
    print('loading game assets')
    if not preloadsVar.assets then
        repeat task.wait() until preloadsVar.assets
    end

    count = #preloads.assets
    for i = 1, count do
        if not loading then break end
        gui.MainFrame.LoadingText.Text = "Loading Game Assets... " .. tostring(i) .. "/" .. tostring(count)
        ContentProvider:PreloadAsync({preloads.assets[i]})
    end
    
    loading = false
end

function FINISH()
    if isPlayingIntro or loading then
        repeat task.wait() until not isPlayingIntro and not loading
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