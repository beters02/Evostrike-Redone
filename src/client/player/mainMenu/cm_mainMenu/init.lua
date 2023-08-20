--[[
	Open/Close input is registered in cms_mainMenu
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Players = game:GetService("Players")

local main = {}

-- init

function main.initialize(gui)
    main.player = Players.LocalPlayer
    main.gui = gui
    main.bgframe = main.gui:WaitForChild("BG")
    main.buttsidefr = main.gui:WaitForChild("ButtonSideFR")
    main.buttsidefrdefsize = main.buttsidefr.Size
    main.buttsidefrdefpos = main.buttsidefr.Position

    main.var = {opened = false}
    main.initTweens()

	main.buttonSideFrame.init()
	
	main.page = require(Players.LocalPlayer.PlayerScripts.mainMenu.cm_mainMenu.page).init(main)

	return main
end

function main.initTweens()
    local bgframe = main.bgframe
    local buttonsidefr = main.buttsidefr

    main.tweens = {}
    main.playingtweens = {}
    main.tweens.bgOpen = TweenService:Create(bgframe.BGImage, TweenInfo.new(.2, Enum.EasingStyle.Circular), {ImageTransparency = 0})
    main.tweens.bgClose = TweenService:Create(bgframe.BGImage, TweenInfo.new(.3, Enum.EasingStyle.Circular), {ImageTransparency = 1})

    local bsfOTweenProp = {Position = UDim2.fromScale(.5, .5), AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromScale(main.buttsidefrdefsize.X.Scale + .15, main.buttsidefrdefsize.Y.Scale + .15)}
    local bsfCTweenProp = {Position = main.buttsidefrdefpos, AnchorPoint = Vector2.new(0, 0), Size = main.buttsidefrdefsize}
    main.tweens.bsfOpen = TweenService:Create(buttonsidefr, TweenInfo.new(.7), bsfOTweenProp)
    main.tweens.bsfClose = TweenService:Create(buttonsidefr, TweenInfo.new(.4, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), bsfCTweenProp)

end

-- main

function main.open()
	main.var.opened = true

	-- prepare frames
	main.page:CloseAllPages()
	main.prepareButtonSideOpen()
	main.prepareBackgroundOpen()

	-- connect button side frame
	main.buttonSideFrame.connect()

	-- open menu
	main.gui.Enabled = true
	main.moveButtonFrameMiddle()

	UserInputService.MouseIconEnabled = true
	
	print('opened!')
end

function main.close()
	main.var.opened = false

	main.page:CloseAllPages()
	main.stopAllMenuTweens()
	main.buttonSideFrame.disconnect()
	
	main.gui.Enabled = false
	UserInputService.MouseIconEnabled = false
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

-- button side frame main util

function main.prepareButtonSideOpen()
    local buttonsidefr = main.buttsidefr

	buttonFrameMovedDefault = false
	buttonsidefr.Size = main.buttsidefrdefsize
	buttonsidefr.Position = main.buttsidefrdefpos
	buttonsidefr.AnchorPoint = Vector2.new(0,0)
end

function main.prepareBackgroundOpen()
	main.bgframe.BGImage.ImageTransparency = 1
end

function main.moveButtonFrameDefault()
	if not buttonFrameMovedDefault then
		buttonFrameMovedDefault = true
		main.playMenuTween(main.tweens.bsfClose)
	end
end

function main.moveButtonFrameMiddle()
	coroutine.wrap(function()
		buttonFrameMovedDefault = false
		main.playMenuTween(main.tweens.bgOpen)
		main.playMenuTween(main.tweens.bsfOpen)
	end)()
end

-- button side frame
local bsf = {}

function bsf.init()
	bsf.canvasGroup = main.buttsidefr:WaitForChild("CanvasGroup")
	bsf.buttonData = {}
	bsf.connections = {}
end

function bsf.connect()
	for _, button in pairs(bsf.canvasGroup:GetChildren()) do
		if button:IsA("TextButton") then

			if bsf.buttonData[button.Name] == nil then
				local t = {DefaultPosition = button.Position, DefaultSize = button.Size}
				bsf.buttonData[button.Name] = t
			end

			table.insert(bsf.connections, button.MouseEnter:Connect(function()
				bsf.hoverIn(button)
			end))

			table.insert(bsf.connections, button.MouseLeave:Connect(function()
				bsf.hoverOut(button, bsf.buttonData[button.Name].DefaultPosition)
			end))

			table.insert(bsf.connections, button.MouseButton1Click:Connect(function()
				bsf.click(button)
			end))
		end
	end
end

function bsf.disconnect()
	for _, conn in pairs(bsf.connections) do
		conn:Disconnect()
	end
	bsf.connections = {}
	--main.page:ClosePage("Options") -- force options update on close
end

function bsf.click(button)
	local frameName = string.gsub(button.Name, "Button", "")
	local frame = main.gui:FindFirstChild(frameName .. "Frame")

	main.moveButtonFrameDefault()
	button:SetAttribute("canTween", false)
	
	-- if the page is already open, then close it
	local close = false
	if main.page:GetOpenPages()[frameName] then
		main.moveButtonFrameMiddle()
		close = true
	end

	print("opening " .. tostring(not close))

	if close then
		main.page:ClosePage(frameName)
	else
		main.page:OpenPage(frameName)
	end
	
	button:SetAttribute("canTween", true)

	--TODO: play menu souind
	--game:GetService("SoundService"):PlayLocalSound(gui:WaitForChild("Sounds").selectSound)

	--TODO: button animation
end

function bsf.hoverIn(button)
	button.TextColor3 = Color3.new(0.541176, 0.541176, 0.541176)
end

function bsf.hoverOut(button, defaultPos)
	button.TextColor3 = Color3.fromRGB(232, 241, 255)
end

-- finalize
main.buttonSideFrame = bsf

return main