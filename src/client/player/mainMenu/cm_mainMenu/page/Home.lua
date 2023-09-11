local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.mainMenu.Popup)
local EvoMM = require(ReplicatedStorage:WaitForChild("Services"):WaitForChild("EvoMMWrapper"))

local getGamemodeRemote = ReplicatedStorage:WaitForChild("gamemode"):WaitForChild("remote"):WaitForChild("Get")
local gamemodeChangedRemote = ReplicatedStorage.gamemode.remote.ChangedEvent
local requestQueueFunction = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("requestQueueFunction")

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
    self = setmetatable(play, {__index = self})
    self.connections = {}
    self.var = {nextClickAllow = tick()}

    -- connect gamemode changed
    gamemodeChangedRemote.OnClientEvent:Connect(function(gamemode: string)
        self._lastGotGamemode = gamemode
        self:_preparePageGamemode(gamemode, true)
    end)

    -- grab the current gamemode
    self._lastGotGamemode = getGamemodeRemote:InvokeServer()
    self:_preparePageGamemode(self._lastGotGamemode, false)

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

function play:_preparePageGamemode(gamemode: string, onChange)
    if gamemode == "Lobby" and onChange then
        self:_enableLoadStarterIslandButton()
    else
        self:_enableBackToLobbyButton()
    end
end

function play:_enableLoadStarterIslandButton()
    self.Location.Card_StarterIsland.Visible = true
    self.Location.Card_BackToLobby.Visible = false
    self._starterConn = self.Location.Card_StarterIsland.MouseButton1Click:Connect(function()
        local success = self.Location.Parent.SpawnRemote:InvokeServer()
        if success then
            self._starterConn:Disconnect()
            self._closeMain()
            self.Location.Card_StarterIsland.Visible = false
        end
        self._starterConn:Disconnect()
    end)
end

function play:_enableBackToLobbyButton()
    self.Location.Card_StarterIsland.Visible = false
    self.Location.Card_BackToLobby.Visible = true
    self._backToLobbyConn = self.Location.Card_BackToLobby.MouseButton1Click:Connect(function()
        self._closeMain()
        requestQueueFunction:InvokeServer("TeleportPublicSolo", "Lobby")
        self._starterConn:Disconnect()
    end)
end

--

function play:_soloButtonClick()

    if self._lastGotGamemode ~= "Lobby" then
        Popup.burst("You can only do this in the lobby!", 3)
        return
    end

    self.Location.Visible = false
    self.Location.Parent.SoloPopupRequest.Visible = true

    local connections
    connections = {
        self.Location.Parent.SoloPopupRequest.Card_Stable.MouseButton1Click:Once(function()
            connections[2]:Disconnect()
            connections[3]:Disconnect()
            Popup.burst("Teleporting!", 3)
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Location.Visible = true

            requestQueueFunction:InvokeServer("TeleportPrivateSolo", "Stable")
            connections[1]:Disconnect()
        end),
        self.Location.Parent.SoloPopupRequest.Card_Unstable.MouseButton1Click:Once(function()
            connections[1]:Disconnect()
            connections[3]:Disconnect()
            Popup.burst("Teleporting!", 3)
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Location.Visible = true

            requestQueueFunction:InvokeServer("TeleportPrivateSolo", "Unstable")
            connections[2]:Disconnect()
        end),
        self.Location.Parent.SoloPopupRequest.Card_Cancel.MouseButton1Click:Once(function()
            connections[1]:Disconnect()
            connections[2]:Disconnect()
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Location.Visible = true
            self._playSoloDebounce = false
            connections[3]:Disconnect()
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
            local success = EvoMM:RemovePlayerFromQueue(game:GetService("Players").LocalPlayer)
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
            local success, err = EvoMM:AddPlayerToQueue(game:GetService("Players").LocalPlayer, "Deathmatch")
            if not success then warn("Couldn't add player to queue. Error: " .. tostring(err)) end
            
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

--

return play