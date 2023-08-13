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
	main.page.init()
	main.page.options.init()

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
	main.page.closeAllPages()
	main.prepareButtonSideOpen()
	main.prepareBackgroundOpen()

	-- connect button side frame
	main.buttonSideFrame.connect()

	-- open menu
	main.gui.Enabled = true 
	main.moveButtonFrameMiddle()

	UserInputService.MouseIconEnabled = true
	
end

function main.close()
	main.var.opened = false
	main.stopAllMenuTweens()
	main.buttonSideFrame.disconnect()
	main.page.closeAllPages()
	main.gui.Enabled = false
	UserInputService.MouseIconEnabled = false
end

function main.toggle()
    --local console = player.PlayerGui:FindFirstChild("console") -- if console is open, dont open menu
	--if console and console.Enabled then return end
	if main.player:GetAttribute("loading") then return end -- if player is loading then dont open menu

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
	--main.page.close("Options") -- force options update on close
end

function bsf.click(button)
	local frameName = string.gsub(button.Name, "Button", "")
	local frame = main.gui:FindFirstChild(frameName .. "Frame")

	main.moveButtonFrameDefault()
	button:SetAttribute("canTween", false)
	
	-- if the page is already open, then close it
	local close = false
	if table.find(main.page.openPages, frameName) then
		main.moveButtonFrameMiddle()
		close = true
	end

	main.page.closeAllPages()

	if not close then
		main.page.open(frameName)
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

-- page
local page = {}

function page.init()
	page.openPages = {}
end

function page.open(pageName)
	local pageObj = main.gui:FindFirstChild(pageName .. "Frame")
	if not pageObj then warn("MainMenu: Could not find page " .. pageName .. "!") end
    pageObj.Visible = true
	table.insert(main.page.openPages, pageName)
end

function page.close(pageName)
    local pageObj = main.gui:FindFirstChild(pageName .. "Frame")
	if not pageObj then warn("MainMenu: Could not find page " .. pageName .. "!") end
    pageObj.Visible = false
	table.remove(main.page.openPages, table.find(page.openPages, pageName))
end

function page.closeAllPages()
	for i, v in pairs(page.openPages) do
		page.close(v)
	end
	main.closeAllFrames()
	main.page.openPages = {}
end

-- options page

local optionsPage = {}

function optionsPage.init()
	local clientPlayerDataModule = require(Framework.shm_clientPlayerData.Location)
	if not clientPlayerDataModule.stored then repeat task.wait() until clientPlayerDataModule.stored end
	optionsPage.playerdata = require(Framework.shm_clientPlayerData.Location)
	optionsPage.connections = {}
	optionsPage.crosshairModule = optionsPage.getPlayerCrosshairModule()
	main.page.options = optionsPage
	main.optionspageobj = main.gui:WaitForChild("OptionsFrame")
	main.optcrosshairfr = main.optionspageobj.General.Crosshair

	main.page.options.updateCrosshairFrame()
	main.page.options.connect()
end

function optionsPage.connect()
	for i, tab in pairs({Crosshair = main.optcrosshairfr:GetChildren()}) do -- init crosshair settings
		for _, frame in pairs(tab) do
			if not frame:IsA("Frame") then continue end

			local textBox = frame:FindFirstChildWhichIsA("TextBox")
			if textBox then
				table.insert(main.page.options.connections, textBox.FocusLost:Connect(function(enterPressed)
					typingFocusFinished(enterPressed, textBox, frame)
				end))
				continue
			end

			local textButton = frame:FindFirstChildWhichIsA("TextButton")
			if textButton then
				table.insert(main.page.options.connections, textButton.MouseButton1Click:Connect(function()
					--optionsBooleanInteract(textButton, i)
				end))
			end
		end
	end
end

function optionsPage.disconnect()
	for i, v in pairs(main.page.options.connections) do
		v:Disconnect()
	end
	main.page.options.connections = nil
end

function optionsPage.open()
	main.page.options.connect()
end

function optionsPage.close()
	main.page.options.disconnect()
	--ProfileService.invokeFromClient("Options", "update")
end

--

function optionsPage.updateCrosshairFrame()
	for _, frame in pairs(main.optcrosshairfr:GetChildren()) do
		if not frame:IsA("Frame") then continue end
		local dataKey = string.lower(string.sub(frame.Name, 3))
		frame:WaitForChild("button").Text = tostring(main.page.options.playerdata.get("crosshair", dataKey))
	end
end

function optionsPage.getPlayerCrosshairModule()
	local module = require(main.player.Character:WaitForChild("crosshair"):WaitForChild("m_crosshair"))
	if not module._isInit then repeat task.wait() until module._isInit end
	return module
end

function typingFocusFinished(enterPressed, button, frame, isButton)
	local parentSettingDataPrefix = frame:FindFirstAncestorWhichIsA("Frame"):GetAttribute("DataPrefix")
	local dataKey = string.lower(string.sub(frame.Name, 3))
	--local currValue = ProfileService.invokeFromClient("Options", "getValue", {parrentSettingDataPrefix, dataKey})
	local currValue = main.page.options.playerdata.get(parentSettingDataPrefix, dataKey)

	if enterPressed then
		local newValue = tonumber(button.Text)
		if not newValue then
			button.Text = tostring(currValue)
			return
		end

		--main.page.options.profile[parentSettingDataPrefix][dataKey] = newValue
		main.page.options.playerdata.set(parentSettingDataPrefix, dataKey, newValue)

		if parentSettingDataPrefix == "crosshair" then
			main.page.options.updateCrosshairFrame()
			main.page.options.crosshairModule:updateCrosshair(dataKey, newValue)
		end
	else
		button.Text = tostring(currValue)
	end
end

-- finalize
main.buttonSideFrame = bsf
main.page = page
main.page.options = optionsPage

return main