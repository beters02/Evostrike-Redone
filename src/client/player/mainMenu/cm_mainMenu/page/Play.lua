local requestQueueRemote = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("requestQueueFunction")
local TweenService = game:GetService("TweenService")

local play = {}
play.__index = play

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

    --self:_connectSoloButton()
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
            if not success then warn("Couldnt remove player from queue") return end

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
            local success = requestQueueRemote:InvokeServer("Add", "Deathmatch")

            if success then
                if tween then tween:Destroy() end
                -- show in queue text
                tween = TweenService:Create(casPage.Card_Deathmatch.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 1})
                tween:Play()
                task.delay(0.5, function()
                    casPage.Card_Deathmatch.InQueueText.TextLabel.Text = "YOU ARE IN QUEUE"
                    tween = TweenService:Create(casPage.Card_Deathmatch.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 0})
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