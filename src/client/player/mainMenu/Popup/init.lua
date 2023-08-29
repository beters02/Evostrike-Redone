local TS = game:GetService("TweenService")
local P = game:GetService("Players")

local defaultTextGui = script:WaitForChild("Gui")

local currentText = nil
local currentInTween = nil
local currentOutTween = nil
local currentTextOutEvent = nil
local currentTextOutConn = nil

local function textIn(text)
	if currentTextOutConn ~= nil then currentTextOutConn:Disconnect() end
	currentText = defaultTextGui:Clone()
	local textLabel = currentText:WaitForChild("TextLabel")
	textLabel.TextTransparency = 1
	textLabel.TextStrokeTransparency = 1
	textLabel.Text = text or "Press 'E'"	
	currentInTween = TS:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 0.1, TextStrokeTransparency = 0.1})
	currentInTween:Play()
	currentOutTween = TS:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 1, TextStrokeTransparency = 1})
	currentTextOutEvent = Instance.new("BindableEvent")
	currentTextOutConn = currentTextOutEvent.Event:Once(function()
		currentTextOut()
	end)
	currentText.Parent = P.LocalPlayer.PlayerGui
	currentText.Enabled = true
end

function currentTextOut()
	currentOutTween:Play()
	currentTextOutConn:Disconnect()
	currentTextOutConn = currentOutTween.Completed:Once(function()
		currentText:Destroy()
		currentText = nil
	end)
end

local currentCoro = nil
local module = {}

function module.new(text)
	textIn(text)
end

function module.stop()
	currentTextOut()
end

function module.burst(text, length)
	if currentCoro then currentTextOut() coroutine.close(currentCoro) end
	textIn(text)
	currentCoro = coroutine.create(function()
		task.wait(length)
		currentTextOut()
	end)
	coroutine.resume(currentCoro)
end

return module
