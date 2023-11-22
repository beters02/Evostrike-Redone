--[[
	Open/Close input is registered in cms_mainMenu
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Players = game:GetService("Players")
local States = require(Framework.Module.m_states)
local UIState = States.State("UI")
local player = Players.LocalPlayer

local main = {}

-- init
function main.initialize(gui)
    main.player = Players.LocalPlayer
    main.gui = gui
    main.bgframe = main.gui:WaitForChild("BG")
	main.topBar.init()
    main.var = {opened = false, menuType = main.gui:GetAttribute("MenuType"), loading = false}
	main.page = require(Players.LocalPlayer.PlayerScripts.MainMenu.page).init(main)

	main.isInit = true

	if player:GetAttribute("Loaded") then
		main.open()
	else
		main.close()
		main.var.loading = true
		task.spawn(function()
			repeat task.wait() until player:GetAttribute("Loaded")
			main.open()
			main.var.loading = false
		end)
	end
	return main
end

-- menu type
type MenuType = "Game" | "Lobby"
function main.setMenuType(mtype: MenuType)
	if not main.isInit then
		if not main.processing then
			main.processing = task.spawn(function()
				print("MainMenu accessed before init. Waiting..")
				repeat task.wait() until main.isInit
				main.setMenuType(mtype)
				main.processing = nil
			end)
		end
		return
	end
	main.page._stored.Home:SetMenuType(mtype)
	print("Set MainMenu Type!")
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

function main.topBar.connect()
	main.topBar.disconnect()
	main.topBar.connections = {}

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