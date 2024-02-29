--[[
	Open/Close input is registered in cms_mainMenu
]]

<<<<<<< Updated upstream
=======
--[[ CONFIG ]]
local DISABLE_CHAT_RETRIES = 5
local MENU_OPEN_WITH_HOMEPAGE = true

local TOPBAR_BUTTON_DEFAULT_COLOR = Color3.fromRGB(23, 29, 38)
local TOPBAR_BUTTON_ACTIVE_COLOR = Color3.fromRGB(95, 120, 157)

local TOPBAR_BUTTON_OPEN_FADEIN_LENGTH = .8
local TOPBAR_BAR_OPEN_LENGTH = .8

local TOPBAR_BUTTON_CLOSE_FADEOUT_LENGTH = .6
local TOPBAR_BAR_CLOSE_LENGTH = .7

local TOPBAR_BUTTON_HOVER_FADEIN_LENGTH = 1
local TOPBAR_BUTTON_HOVER_FADEOUT_LENGTH = 1

local ReplicatedStorage = game:GetService("ReplicatedStorage")
>>>>>>> Stashed changes
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Players = game:GetService("Players")
local States = require(Framework.Module.m_states)
local UIState = States.State("UI")
local GamemodeService = require(Framework.Service.GamemodeService2)
local player = Players.LocalPlayer

local main = {}

-- init
function main.initialize(gui)
    main.player = Players.LocalPlayer
    main.gui = gui
    main.bgframe = main.gui:WaitForChild("BG")
	main.topBar.init()
    main.var = {opened = false, menuType = main.gui:GetAttribute("MenuType"), loading = false}
	main.page = require(Players.LocalPlayer.PlayerScripts.MainMenu.page).init(main, main.gui:GetAttribute("IsAdmin"))
	main.isInit = true
	main.initTime = tick()

<<<<<<< Updated upstream
	if player:GetAttribute("Loaded") then
		main.open()
	else
		main.close()
		main.var.loading = true
		task.spawn(function()
			repeat task.wait() until player:GetAttribute("Loaded")
			main.open()
			main.var.loading = false
=======
-- Initialize Pages, Sounds and GamemodeService
function MainMenu:Initialize(gui)
    self.Gui = gui
    self.CurrentMenuType = GamemodeService:GetMenuType()

    initPages(self)
    initButtonSounds(self)
    initTopBar(self)

    self.BaseConnections.MenuTypeChanged = GamemodeService:MenuTypeChanged(menuTypeChanged)
    self.CurrentOpenPage = getPage("Home")

    if self.CurrentMenuType == "Lobby" then
        self:Open()
    end
end

-- Open the Menu, Re-opens last open page
function MainMenu:Open()
    self.Gui.Enabled = true
    if self.CurrentOpenPage then
        self.CurrentOpenPage:Open()
    end
    UIState:removeOpenUI("MainMenu")
	UIState:addOpenUI("MainMenu", self.Gui, true)
    task.spawn(function()
        disableChat()
    end)
end

-- Close the Menu, Closes current page and sets to last open
function MainMenu:Close()
    self:ClosePage()
    
    if MENU_OPEN_WITH_HOMEPAGE then
        self.CurrentOpenPage = self.Pages.Home
    end

    self.Gui.Enabled = false
    UIState:removeOpenUI("MainMenu")
    task.spawn(function()
        enableChat()
    end)
end

-- Automatically Closes Current Page and Opens New One
function MainMenu:OpenPage(pageName)
    local newPage = getPage(pageName)
    self:ClosePage()
    newPage:Open()
    self.CurrentOpenPage = newPage
end

-- Closes the Currently Opened Page
function MainMenu:ClosePage()
    if self.CurrentOpenPage then
        self.CurrentOpenPage:Close()
    end
end

function MainMenu:GetPage(page: string)
    return self.Pages[page]
end

-- Play a Button Sound
function MainMenu:PlayButtonSound(buttonType)
    self.ButtonSounds[buttonType]:Play()
end

-- Get the CurrentMenuType
function MainMenu.MenuType()
    return MainMenu.CurrentMenuType
end

function MainMenu:OpenTopBar()
    openTopBarTween(self)
    connectTopBar(self)
end

function MainMenu:CloseTopBar()
    closeTopBarTween(self)
    disconnectTopBar(self)
end

--
--
--

function getPage(pageName) return MainMenu.Pages[pageName] end
function getPages() return MainMenu.Pages end

function initButtonSounds(self)
    local bsounds = self.Gui:WaitForChild("Sounds")
    for i, v in pairs(Enum_ButtonSoundNames) do
        self.ButtonSounds[i] = bsounds:FindFirstChild(v)
    end
end

function menuTypeChanged(newMenuType)
    local self = MainMenu
    if self.CurrentMenuType == newMenuType then return end
    self.CurrentMenuType = newMenuType
    for _, page in pairs(getPages()) do
        page:MenuTypeChanged(newMenuType)
    end
end

function initPages(self)
    -- Frames which names end in "Frame: are initialized as pages and moved to Pages Folder
    local pagesFolder = Instance.new("Folder", self.Gui)
    pagesFolder.Name = "Pages"
    for _, frame in pairs(self.Gui:GetChildren()) do
        if not string.match(frame.Name, "Frame") then continue end
        frame.Parent = pagesFolder
        local pageName = string.gsub(frame.Name, "Frame", "")

        -- if we can't find a module for the page, it gets the Base class.
        local module = script.Page:FindFirstChild(pageName) or script.Page
        self.Pages[pageName] = require(module).new(self, frame)
        self.Pages[pageName]:MenuTypeChanged(self.CurrentMenuType)
    end
end

function initTopBar(self)
    local tb = self.Gui.TopBar
    self.Var.topBarDefSizeY = tb.Size.Y.Scale

    local tboti = TweenInfo.new(TOPBAR_BAR_OPEN_LENGTH, Enum.EasingStyle.Cubic)
    local tbcti = TweenInfo.new(TOPBAR_BAR_CLOSE_LENGTH, Enum.EasingStyle.Cubic)
    local tbbofiti = TweenInfo.new(TOPBAR_BUTTON_OPEN_FADEIN_LENGTH, Enum.EasingStyle.Cubic)
    local tbbofoti = TweenInfo.new(TOPBAR_BUTTON_CLOSE_FADEOUT_LENGTH, Enum.EasingStyle.Cubic)
    local tbbhiti = TweenInfo.new(TOPBAR_BUTTON_HOVER_FADEIN_LENGTH, Enum.EasingStyle.Cubic)
    local tbbhoti = TweenInfo.new(TOPBAR_BUTTON_HOVER_FADEOUT_LENGTH, Enum.EasingStyle.Cubic)

    self.Tweens.TopBarOpen = {}
    self.Tweens.TopBarClose = {}
    self.Tweens.TopBarHoverOn = {}
    self.Tweens.TopBarHoverOff = {}
    self.Tweens.TopBarOpen.Bar = TweenService:Create(tb, tboti, {Size = UDim2.fromScale(1, self.Var.topBarDefSizeY)})
    self.Tweens.TopBarClose.Bar = TweenService:Create(tb, tbcti, {Size = UDim2.fromScale(1, 0)})

    for _, v in pairs(tb:GetChildren()) do
        if v.Name == "CreditsButtonFrame" then
            continue
        end
        self.Tweens.TopBarOpen[v.Name] = TweenService:Create(v:WaitForChild("TextButton"), tbbofiti, {TextTransparency = 0})
        self.Tweens.TopBarOpen[v.Name .. "_Stroke"] = TweenService:Create(v.TextButton.UIStroke, tbbofiti, {Transparency = 0})
        self.Tweens.TopBarClose[v.Name] = TweenService:Create(v.TextButton, tbbofoti, {TextTransparency = 1})
        self.Tweens.TopBarClose[v.Name .. "_Stroke"] = TweenService:Create(v.TextButton.UIStroke, tbbofoti, {Transparency = 1})
        self.Tweens.TopBarHoverOn[v.Name] = TweenService:Create(v.TextButton.UIStroke, tbbhiti, {Color = TOPBAR_BUTTON_ACTIVE_COLOR})
		self.Tweens.TopBarHoverOff[v.Name] = TweenService:Create(v.TextButton.UIStroke, tbbhoti, {Color = TOPBAR_BUTTON_DEFAULT_COLOR})
        v.TextButton.UIStroke.Transparency = 1
        v.TextButton.TextTransparency = 1
    end

    tb.Size = UDim2.fromScale(1, 0)
end

function connectTopBar(self)
    for _, frame: Frame in pairs(self.Gui.TopBar:GetChildren()) do
        if frame.Name == "CreditsButtonFrame" then
            continue
        end
        self.TopBarConnections[frame.Name .. "Began"] = frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                hoverOnTopBarTween(self, frame)
			end
        end)
        self.TopBarConnections[frame.Name .. "Ended"] = frame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                hoverOffTopBarTween(self, frame)
			end
        end)
        self.TopBarConnections[frame.Name .. "Activated"] = frame.TextButton.MouseButton1Click:Connect(function()
            self:PlayButtonSound("Select1")
            self:OpenPage(string.gsub(frame.Name, "ButtonFrame", ""))
        end)
    end
end

function disconnectTopBar(self)
    for _, v in pairs(self.TopBarConnections) do
        v:Disconnect()
    end
end

function openTopBarTween(self)
    self.Tweens.TopBarOpen.Bar:Play()
    self.Tweens.TopBarOpen.Bar.Completed:Once(function()
        for i, v in pairs(self.Tweens.TopBarOpen) do
            if i == "Bar" then
                continue
            end
            v:Play()
        end
    end)
end

function closeTopBarTween(self)
    local last
    for i, v in pairs(self.Tweens.TopBarClose) do
        if i == "Bar" then
            continue
        end
        v:Play()
        last = v
    end
    for _, frame in pairs(self.Gui.TopBar:GetChildren()) do
        if frame.Name == "CreditsButtonFrame" then
            continue
        end
        hoverOffTopBarTween(self, frame)
    end
    last.Completed:Once(function()
        self.Tweens.TopBarClose.Bar:Play()
    end)
end

function hoverOnTopBarTween(self, frame)
    local offTween = self.Tweens.TopBarHoverOff[frame.Name]
    local onTween = self.Tweens.TopBarHoverOn[frame.Name]
    if offTween.PlaybackState == Enum.PlaybackState.Playing then
        offTween:Pause()
    end
    onTween:Play()
end

function hoverOffTopBarTween(self, frame)
    local offTween = self.Tweens.TopBarHoverOff[frame.Name]
    local onTween = self.Tweens.TopBarHoverOn[frame.Name]
    if onTween.PlaybackState == Enum.PlaybackState.Playing then
        onTween:Pause()
    end
    offTween:Play()
end

function disableChat()
    local retries = 0
	local success,message
	repeat
		success,message = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
>>>>>>> Stashed changes
		end)
	end

	main.typeChangedConn = GamemodeService:MenuTypeChanged(function(new)
		main.setMenuType(new)
		main.var.menuType = new
	end)
	main.setMenuType(main.var.menuType)
	return main
end

-- menu type
type MenuType = "Game" | "Lobby"
function main.setMenuType(mtype: MenuType)
	-- Dont allow access before init
	if not main.isInit and not main.processing then
		main.processing = task.spawn(function()
			print("MainMenu accessed before init. Waiting..")
			repeat task.wait() until main.isInit
			main.setMenuType(mtype)
			main.processing = nil
		end)
		return
	end
	main.page._stored.Home:SetMenuType(mtype)
end

-- main
function main.open()
	main.var.opened = true
	main.page:CloseAllPages()
	main.topBar.connect()
	main.topBar.activated(main.topBar.buttonFrames.Home)
	main.gui.Enabled = true
	UIState:removeOpenUI("MainMenu")
	UIState:addOpenUI("MainMenu", main.gui, true)
end

function main.close()
	main.var.opened = false
	main.topBar.disconnect()
	main.page:CloseAllPages()
	main.gui.Enabled = false
	UIState:removeOpenUI("MainMenu")
end

function main.toggle()
	if main.var.opened then
		main.close()
		task.wait()
	else
		main.open()
		task.wait()
	end
end

function main.conectOpenInput()
	main.disconectOpenInput()
	main.inputConn = UserInputService.InputBegan:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.M then
			if player:GetAttribute("Typing") then return end
			if player:GetAttribute("loading") then return end -- if player is loading then dont open menu
			main.toggle()
		end
	end)
end

function main.disconectOpenInput()
	if main.inputConn then
		main.inputConn:Disconnect()
		main.inputConn = nil
	end
end

-- main util
function main.closeAllFrames(button)
	for i, v in pairs(main.gui:GetChildren()) do -- close all frames except mainButtonFr
		if v:IsA("Frame") and (not button and string.match(v.Name, "Frame")) then
			v.Visible = false
		end
	end
end

function main.playMenuTween(tween)
	tween:Play()
	table.insert(main.playingtweens, tween)
	tween.Completed:Once(function()
		table.remove(main.playingtweens, table.find(main.playingtweens, tween))
	end)
end

function main.stopMenuTween(tween)
	tween:Pause()
	table.remove(main.playingtweens, table.find(main.playingtweens, tween))
end

function main.stopAllMenuTweens()
	for i, v in pairs(main.playingtweens) do
		v:Pause()
	end
	main.playingtweens = {}
end

-- top bar
export type TopBarButtonFrame = {
	PageName: string,
	Frame: Frame,
	Var: table
}

local TOPBAR_BUTTON_ACTIVE_COLOR = Color3.fromRGB(95, 120, 157)

main.topBar = {
	gui = false,
	buttonFrames = {}
}

function main.topBar.init()
	main.topBar.gui =  main.gui:WaitForChild("TopBar")
	for _, frame in pairs(main.topBar.gui:GetChildren()) do
		local pageName =  frame.Name:gsub("ButtonFrame", "")
		if not frame:IsA("Frame") or main.topBar.buttonFrames[pageName] then continue end
		
		main.topBar.buttonFrames[pageName] = {
			PageName = pageName,
			Frame = frame,
			Button = frame:WaitForChild("TextButton"),
			Var = {isHovering = false, defaultStrokeColor = frame.TextButton:WaitForChild("UIStroke").Color}
		}:: TopBarButtonFrame
		main.topBar.buttonFrames[pageName].Tweens = main.topBar.initTweens(main.topBar.buttonFrames[pageName])
	end
end

function main.topBar.initTweens(frame: TopBarButtonFrame)
	return {
		hoverOn = TweenService:Create(frame.Button.UIStroke, TweenInfo.new(1), {Color = TOPBAR_BUTTON_ACTIVE_COLOR}),
		hoverOff = TweenService:Create(frame.Button.UIStroke, TweenInfo.new(1), {Color = frame.Var.defaultStrokeColor})
	}
end

local function ScaleToOffset(x)
	local cam = workspace.Camera
	local viewportSize = cam.ViewportSize
	x *= viewportSize.X
	return math.round(x)
end

local function scaleTopBarFrames(titleFrame)
	local size = ScaleToOffset(titleFrame.Size.Y.Scale) / 50
	print(size)
	for _, buttonFrame in pairs(main.topBar.gui:GetChildren()) do
		pcall(function()
			buttonFrame.TextButton.TextScaled = false
			buttonFrame.TextButton.TextSize = size
		end)
	end
end

function main.topBar.connect()
	main.topBar.disconnect()
	main.topBar.connections = {}

	local lastTextSize = 0
	local longestTopBarTitle = main.topBar.gui.InventoryButtonFrame.TextButton
	main.topBar.Update = RunService.RenderStepped:Connect(function()
		if tick() - main.initTime < 3 then
			return
		end
		if longestTopBarTitle.TextSize ~= lastTextSize then
			lastTextSize = longestTopBarTitle.TextSize
			scaleTopBarFrames(longestTopBarTitle)
		end
	end)

	for _, frame: TopBarButtonFrame in pairs(main.topBar.buttonFrames) do
		main.topBar.connections[frame.PageName .. "Began"] = frame.Frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				main.topBar.hoverOn(frame)
			end
		end)
		main.topBar.connections[frame.PageName .. "Ended"] = frame.Frame.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				main.topBar.hoverOff(frame)
			end
		end)
		main.topBar.connections[frame.PageName .. "Activated"] = frame.Button.MouseButton1Click:Connect(function()
			main.topBar.activated(frame)
		end)
	end
end

function main.topBar.disconnect()
	if not main.topBar.connections then return end
	for _, v in pairs(main.topBar.connections) do
		v:Disconnect()
	end
	main.topBar.connections = false
end

function main.topBar.activated(frame: TopBarButtonFrame)
	main.page:OpenPage(frame.PageName)
end

function main.topBar.hoverOn(frame: TopBarButtonFrame)
	frame.Var.isHovering = true
	if frame.Tweens.hoverOff.PlaybackState == Enum.PlaybackState.Playing then
		frame.Tweens.hoverOff:Pause()
	end
	frame.Tweens.hoverOn:Play()
end

function main.topBar.hoverOff(frame: TopBarButtonFrame)
	frame.Var.isHovering = false
	if frame.Tweens.hoverOn.PlaybackState == Enum.PlaybackState.Playing then
		frame.Tweens.hoverOn:Pause()
	end
	frame.Tweens.hoverOff:Play()
end

return main