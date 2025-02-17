local UserInputService = game:GetService("UserInputService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local Popup = require(script.Parent.Parent.Parent.Popup)

local keybinds = {}

function keybinds:_connectKeybindsFrame()

    -- connect keybinds
	for i, frame in pairs(self.keybindsFrame.Text:GetChildren()) do
		if not frame:IsA("Frame") then continue end

        local textBox = frame:FindFirstChildWhichIsA("TextBox")
        if textBox then

            table.insert(self.pageconnections, textBox.Focused:Connect(function()
                task.wait(0.07)

                local _conn
                local _inputchangedconn

                -- key pressed
                _conn = UserInputService.InputBegan:Connect(function(input, gp)

                    -- ignore focus or mousedelta
                    if input.UserInputType == Enum.UserInputType.Focus or input.UserInputType == Enum.UserInputType.MouseMovement then return end

                    -- attempt capture and set input
                    local inputStr, dataKey, currValue = self:_textBoxCaptureInput(textBox, input)

                    if inputStr then

                        -- verify string (type check, min/max)
                        local success, err = self:_verifyInputString(inputStr, dataKey)
                        if not success then Popup.new(self.player, tostring(err), 3) textBox.Text = currValue return end

                        -- set
                        self:_setKey(dataKey, inputStr, textBox, currValue)
                    end

                    -- disconnect
                    _inputchangedconn:Disconnect()
                    _conn:Disconnect()
                end)

                -- mouse wheel registered
                _inputchangedconn = UserInputService.InputChanged:Connect(function(input, gp)
                    if input.UserInputType == Enum.UserInputType.MouseWheel then
                        local inputStr, dataKey, currValue = self:_textBoxCaptureInput(textBox, input)
                        if inputStr then
                            local success, err = self:_verifyInputString(inputStr, dataKey)
                            if not success then Popup.new(self.player, tostring(err), 3) textBox.Text = currValue return end
                            self:_setKey(dataKey, inputStr, textBox, currValue)
                        end
    
                        _conn:Disconnect()
                        _inputchangedconn:Disconnect()
                    end
                end)
            end))

            continue
        end
	end

end

function keybinds:_updateKeybindsFrame()
    local playerKeybinds = PlayerData:GetPath("options.keybinds")
    for i, frame in pairs(self.keybindsFrame.Text:GetChildren()) do
        if not frame:IsA("Frame") then continue end
        frame.textBox.Text = playerKeybinds[frame:GetAttribute("DataName")]
    end
end

function keybinds:_textBoxCaptureInput(box, input)

    local parentSettingDataPrefix = box.Parent:FindFirstAncestorWhichIsA("Frame"):GetAttribute("DataPrefix")
	local dataKey = box.Parent:GetAttribute("DataName") or string.lower(string.sub(box.Parent.Name, 3))
	local currValue = PlayerData:GetPath("options.keybinds." .. dataKey)

    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            box:ReleaseFocus()
            return "MouseWheel", dataKey, currValue
        else
            box.Text = currValue
            box:ReleaseFocus()
            return false, "Cannot bind this action to this key."
        end
    else
        
        local keyCode = string.gsub(tostring(input.KeyCode), "Enum.KeyCode.", "")
        box:ReleaseFocus()
        
        return keyCode, dataKey, currValue
    end
end

function keybinds:_verifyInputString(input: string, dataKey: string)
    if input == "MouseWheel" and dataKey ~= "jump" then
        return false, "Cannot bind this action to this key."
    end
    if input == "W" or input == "A" or input == "S" or input == "D" then
        return false, "Cannot bind this action to this key."
    end
    return true
end

function keybinds:_setKey(dataKey, newKeyStr, textBox, currValue)
    
    -- check if key is already bound to another action
    for i, v in pairs(PlayerData:GetPath("options.keybinds")) do
        if v == newKeyStr then
            Popup.new(self.player, "[" .. string.upper(newKeyStr) .. "] already bound to " .. i, 3)
            textBox.Text = currValue
            return
        end
    end

    -- attempt to set
    local success, err = pcall(function()
        PlayerData:SetPath("options.keybinds." .. dataKey, newKeyStr)
    end)

    if success then
        Popup.new(self.player, "Keybind set!", 3)
        textBox.Text = newKeyStr
        PlayerData:Save()
        return
    end

    Popup.new(self.player, "Could not set keybind! " .. tostring(err), 3)

    -- debug
    error(err)
    textBox.Text = currValue
end

return keybinds