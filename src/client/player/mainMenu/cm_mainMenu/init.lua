--[[
	Open/Close input is registered in cms_mainMenu
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Players = game:GetService("Players")
local States = require(Framework.shm_states.Location)
local UIState = States.State("UI")

local main = {}

-- init

function main.initialize(gui)
    main.player = Players.LocalPlayer
    main.gui = gui
    main.bgframe = main.gui:WaitForChild("BG")
	main.topbar = main.gui:WaitForChild("TopBar")
	
    main.var = {opened = false}
	main.page = require(Players.LocalPlayer.PlayerScripts.mainMenu.cm_mainMenu.page).init(main)

	return main
end

-- main

function main.open()
	main.var.opened = true

	-- prepare frames
	main.page:CloseAllPages()

	-- top bar
	main.topBar.connect()

	-- open menu
	main.page:OpenPage("Home")
	main.gui.Enabled = true

	-- set mouse icon enabled
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
main.topBar = {}

function main.topBar.connect()

	main.topBar._connections = {}

	for _, topBarFrame in pairs(main.topbar:GetChildren()) do
		if not topBarFrame:IsA("Frame") then continue end
		local pageName = topBarFrame.Name:gsub("ButtonFrame", "")

		topBarFrame.TextButton.MouseButton1Click:Connect(function()
			main.page:OpenPage(pageName)
		end)
	end

end

function main.topBar.disconnect()
	for _, v in pairs(main.topBar._connections) do
		v:Disconnect()
	end
end

return main