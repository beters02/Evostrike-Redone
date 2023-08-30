local Debris = game:GetService("Debris")
local message = game:GetService("Players").LocalPlayer.PlayerScripts:WaitForChild("mainMenu").cm_mainMenu.sendMessageGui.message
local TweenService = game:GetService("TweenService")

local colors = {
	["error"] = Color3.new(0.666667, 0, 0),
	["message"] = Color3.new(0, 0, 0)
}

local module = function(player, msg, messageType)

	messageType = colors[messageType] and messageType or "message"

	local messageClone = message:Clone()
	messageClone.Label.Text = tostring(msg)
	messageClone.Label.TextColor3 = colors[messageType]
	messageClone.Parent = player.PlayerGui
	
	messageClone.Label.TextTransparency = 1
	TweenService:Create(messageClone.Label, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	messageClone.Enabled = true
	Debris:AddItem(messageClone, 4)

	task.delay(2, function()
		TweenService:Create(messageClone.Label, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
	end)
end

return module