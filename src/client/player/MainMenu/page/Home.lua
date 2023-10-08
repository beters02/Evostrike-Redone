local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local EvoMM = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EvoMMWrapper"))

local GamemodeService = require(ReplicatedStorage:WaitForChild("Services").GamemodeService)
local requestQueueFunction = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("requestQueueFunction")

local ClickDebounce = 0.5

local play = {}

function play:init()
    self = setmetatable(play, self)
    self.connections = {}
    self.coreconnections = {}
    self.var = {nextClickAllow = tick()}

    -- connect gamemode changed
    self.coreconnections.GamemodeServiceMain = GamemodeService.RemoteEvent.OnClientEvent:Connect(function(action, gamemode)
        if action == "GamemodeChanged" then
            self:_preparePageGamemode(gamemode)
        end
    end)

    if not self.CurrentGamemodeSelected then
        local succ, err = pcall(function()
            self:_preparePageGamemode(GamemodeService:GetMenuType())
        end)
        if not succ then warn("PlayPage Cant get current gamemode " .. tostring(err)) end
    end

    return self
end

--

function play:Open()
    self.Location.Visible = true
    self:_connectPlayButtons()
end

function play:Close()
    self.Location.Visible = false
    self.Location.Parent.CasualFrame.Visible = false
    self.Location.Parent.SoloPopupRequest.Visible = false

    self:_disconnectPlayButtons()
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

-- # Gamemode Interaction

play.GamemodeInteractions = {
    Default = function(self)
        self.Location.Card_StarterIsland.Visible = false
        self.Location.Card_BackToLobby.Visible = true

        self.coreconnections.homeActionCardClick = self.Location.Card_BackToLobby.MouseButton1Click:Connect(function()
            self._closeMain()
            requestQueueFunction:InvokeServer("TeleportPublicSolo", "Lobby")
            self.coreconnections.homeActionCardClick:Disconnect(0)
        end)
    end,

    Lobby = function(self)
        self.Location.Card_StarterIsland.Visible = true
        self.Location.Card_BackToLobby.Visible = false
    
        self.coreconnections.homeActionCardClick = self.Location.Card_StarterIsland.MouseButton1Click:Connect(function()

            local succ, err = GamemodeService:AttemptPlayerSpawn()
            if succ then
                self._closeMain()
                self.Location.Card_StarterIsland.Visible = false
                return
            end
            
            warn("PlayPage LoadIntoStarterIsland Error " .. tostring(err))
            return
        end)
    end
}
play.GamemodeInteractions.Deathmatch = play.GamemodeInteractions.Lobby

function play:_preparePageGamemode(gamemode: string)
    task.wait()

    if self.connections.homeActionCardClick then
        self.connections.homeActionCardClick:Disconnect()
    end

    self.CurrentGamemodeSelected = gamemode; -- nice.
                                             -- remove it i dare you!
    (self.GamemodeInteractions[gamemode] or self.GamemodeInteractions.Default)(self)
end

--

function play:_soloButtonClick()

    if self.CurrentGamemodeSelected ~= "Lobby" then
        Popup.burst("You can only do this in the lobby! Current Gamemode is: " .. tostring(self.CurrentGamemodeSelected), 3)
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

local function _casualQueueButtonClicked(self, card, queue)
    if self.var.nextClickAllow > tick() then Popup.burst("Wait a second before requesting!", 1) return end
    self.var.nextClickAllow = tick() + ClickDebounce

    -- check if player is already in queue
    if card:GetAttribute("InQ") then
        
        -- show leaving queue text
        local tween = TweenService:Create(card.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 1})
        tween:Play()
        
        tween.Completed:Once(function()
            if not tween then return end
            card.InQueueText.TextLabel.Text = "LEAVING QUEUE..."
            tween = TweenService:Create(card.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 0})
            tween:Play()
        end)

        -- attempt queue leave
        local success = EvoMM:RemovePlayerFromQueue(game:GetService("Players").LocalPlayer)
        if not success then warn("Couldnt remove player from queue") return end

        card:SetAttribute("InQ", false)

        -- hude queue text
        if tween then tween:Destroy() end
        TweenService:Create(card.InQueueText.TextLabel, TweenInfo.new(1, Enum.EasingStyle.Cubic), {TextTransparency = 1}):Play()

    else
        -- join queue
        card:SetAttribute("InQ", true)

        -- show joining queue text
        card.InQueueText.TextLabel.Text = "JOINING QUEUE..."
        card.InQueueText.TextLabel.TextTransparency = 1
        local tween = TweenService:Create(card.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 0})
        tween:Play()

        -- request add to queue
        local success, err = EvoMM:AddPlayerToQueue(game:GetService("Players").LocalPlayer, queue)
        if not success then warn("Couldn't add player to queue. Error: " .. tostring(err)) end
        
        -- show result text
        local newText = success and "YOU ARE IN QUEUE" or "COULD NOT ADD TO QUEUE"
        if tween then tween:Destroy() end
        tween = TweenService:Create(card.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 1})
        tween:Play()

        task.delay(0.5, function()
            card.InQueueText.TextLabel.Text = newText
            tween = TweenService:Create(card.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 0})
            tween:Play()
        end)

        if not success then
            task.delay(3, function()
                tween:Pause()
                tween = TweenService:Create(card.InQueueText.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {TextTransparency = 1})
                tween:Play()
            end)
        end

    end
end

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

    -- connect queue buttons
    table.insert(self.connections.modes, casPage.Card_Deathmatch.MouseButton1Click:Connect(function()
        _casualQueueButtonClicked(self, casPage.Card_Deathmatch, "Deathmatch")
    end))

    table.insert(self.connections.modes, casPage.Card_1v1.MouseButton1Click:Connect(function()
        _casualQueueButtonClicked(self, casPage.Card_1v1, "1v1")
    end))

    -- connect queue player amount updates
    table.insert(self.connections.modes, EvoMM.Remote.OnClientEvent:Connect(function(action, ...)
        if action == "SetGamemodeQueueCount" then
            local queue: string, amount: number = ...
            local card = casPage["Card_" .. queue]
            card.PlayersInQueueText.TextLabel.Text = card.PlayersInQueueText.TextLabel:GetAttribute("Text") .. tostring(amount)
        end
    end))
end

function play:_disconnectCasualGamemodeButtons()
    if self.connections.modes then for i, v in pairs(self.connections.modes) do v:Disconnect() end end
    self.connections.modes = {}
end

--

return play