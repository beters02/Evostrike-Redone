local requestQueueRemote = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("requestQueueFunction")
local getGamemodeRemote = game:GetService("ReplicatedStorage"):WaitForChild("gamemode"):WaitForChild("remote"):WaitForChild("Get")
local TweenService = game:GetService("TweenService")
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.mainMenu.Popup)

local ClickDebounce = 0.5

local play = {}

function play:Open()
    self.Location.Visible = true

    self:_connectPlayButtons()
end

function play:Close()
    self.Location.Visible = false
    self.Location.Parent.CasualFrame.Visible = false

    self:_disconnectPlayButtons()
end

--

function play:init()
    self = setmetatable(self, play)
    self.connections = {}
    self.var = {nextClickAllow = tick()}
    return self
end

--

function play:_connectPlayButtons()

    -- casual button
    table.insert(self.connections, self.Location.Card_Casual.MouseButton1Click:Connect(function()
        self.Location.Visible = false
        self.Location.Parent.CasualFrame.Visible = true
        self:_connectCasualGamemodeButtons()
    end))

    -- solo button
    table.insert(self.connections, self.Location.Card_Solo.MouseButton1Click:Connect(function()
        self:_soloButtonClick()
    end))

    --self:_connectSpectateButton()
end

function play:_disconnectPlayButtons()
    for i, v in pairs(self.connections) do
        if typeof(v) == "RBXScriptConnection" then
            v:Disconnect()
        elseif typeof(v) == "table" then -- will automatically disconnect connection tables in connections
            for _, c in pairs(v) do c:Disconnect() end
        end
    end
    self.connections = {}
end

--

function play:_soloButtonClick()
    if self._playSoloDebounce and tick() < self._playSoloDebounce then return end
    self._playSoloDebounce = tick() + 5

    task.wait()

    if getGamemodeRemote:InvokeServer() ~= "Lobby" then
        Popup.burst("You can only do this in the lobby!", 3)
        return
    end

    self.Location.Visible = false
    self.Location.Parent.SoloPopupRequest.Visible = true

    local connections
    connections = {
        self.Location.Parent.SoloPopupRequest.Card_Confirm.MouseButton1Click:Once(function()
            Popup.burst("Teleporting!", 3)
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Location.Parent.Enabled = false

            requestQueueRemote:InvokeServer("TeleportPrivateSolo")
            connections[1]:Disconnect()
        end),
        self.Location.Parent.SoloPopupRequest.Card_Cancel.MouseButton1Click:Once(function()
            connections[1]:Disconnect()
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Location.Visible = true
            self._playSoloDebounce = false
            connections[2]:Disconnect()
        end)
    }

end

--

function play:_connectCasualGamemodeButtons()
    local casPage = self.Location.Parent.CasualFrame

    -- disconnect any casual connections jic
    self:_disconnectCasualGamemodeButtons()

    -- connect back button
    table.insert(self.connections.modes, casPage.Button_Back.MouseButton1Click:Connect(function()
        casPage.Visible = false
        self.Location.Visible = true
        self:_disconnectCasualGamemodeButtons()
    end))

    table.insert(self.connections.modes, casPage.Card_Deathmatch.MouseButton1Click:Connect(function()
        if self.var.nextClickAllow > tick() then return end
        self.var.nextClickAllow = tick() + ClickDebounce

        -- check if player is already in queue
        if casPage.Card_Deathmatch:GetAttribute("InQ") then
            
            -- show leaving queue text
            local tween = TweenService:Create(casPage.Card_Deathmatch.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 1})
            tween:Play()
            
            tween.Completed:Once(function()
                if not tween then return end
                casPage.Card_Deathmatch.InQueueText.TextLabel.Text = "LEAVING QUEUE..."
                tween = TweenService:Create(casPage.Card_Deathmatch.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 0})
                tween:Play()
            end)

            -- attempt queue leave
            local success = requestQueueRemote:InvokeServer("Remove", "Deathmatch")
            --if not success then warn("Couldnt remove player from queue") return end

            casPage.Card_Deathmatch:SetAttribute("InQ", false)

            -- hude queue text
            if tween then tween:Destroy() end
            TweenService:Create(casPage.Card_Deathmatch.InQueueText.TextLabel, TweenInfo.new(1, Enum.EasingStyle.Cubic), {TextTransparency = 1}):Play()

        else
            -- join queue
            casPage.Card_Deathmatch:SetAttribute("InQ", true)

            -- show joining queue text
            casPage.Card_Deathmatch.InQueueText.TextLabel.Text = "JOINING QUEUE..."
            casPage.Card_Deathmatch.InQueueText.TextLabel.TextTransparency = 1
            local tween = TweenService:Create(casPage.Card_Deathmatch.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 0})
            tween:Play()

            -- request add to queue
            local success, err = requestQueueRemote:InvokeServer("Add", "Deathmatch")
            if not success then warn("Couldn't add player to queue. Error: " .. err) end
            
            -- show result text
            local newText = success and "YOU ARE IN QUEUE" or "COULD NOT ADD TO QUEUE"
            if tween then tween:Destroy() end
            tween = TweenService:Create(casPage.Card_Deathmatch.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 1})
            tween:Play()

            task.delay(0.5, function()
                casPage.Card_Deathmatch.InQueueText.TextLabel.Text = newText
                tween = TweenService:Create(casPage.Card_Deathmatch.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 0})
                tween:Play()
            end)

            if not success then
                task.delay(3, function()
                    tween:Pause()
                    tween = TweenService:Create(casPage.Card_Deathmatch.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 1})
                    tween:Play()
                end)
            end

        end
    end))
end

function play:_disconnectCasualGamemodeButtons()
    if self.connections.modes then for i, v in pairs(self.connections.modes) do v:Disconnect() end end
    self.connections.modes = {}
end

return play