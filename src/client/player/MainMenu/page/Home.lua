type menuType = "Game" | "Lobby"

-- [[ CONFIGURATION ]]
local CLICK_DEBOUNCE = 0.5
local LOBBY_BOTTOM_DEFAULT_TEXT = "Join Deathmatch"
local LOBBY_BOTTOM_CLICKED_TEXT = "Leave Deathmatch"
local GAME_BOTTOM_DEFAULT_TEXT = "Back to Lobby"

-- [[ SERVICES ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local EvoMM = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EvoMMWrapper"))

local RequestQueueEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("requestQueueFunction")
local RequestSpawnEvent = ReplicatedStorage.Services.GamemodeService2.RequestSpawn
local RequestDeathEvent = ReplicatedStorage.Services.GamemodeService2.RequestDeath

-- | Page Class |

local Home = {}

function Home:init()
    self = setmetatable(Home, self)
    self.connections = {}
    self.coreconnections = {}
    self.var = {nextClickAllow = tick(), currentMenuType = "Lobby", bottomButtonClickedFunc = false, processing = false}
    return self
end

function Home:Open()
    self:OpenAnimations()
    self:ConnectButtons()
end

function Home:Close()
    self:DisconnectButtons()
    self.Location.Visible = false
    self.Location.Parent.CasualFrame.Visible = false
    self.Location.Parent.SoloPopupRequest.Visible = false
end

-- | Button Connections |

function Home:ConnectButtons()
    table.insert(self.connections, self.Location.Card_Casual.MouseButton1Click:Connect(function()
        self.Location.Visible = false
        self.Location.Parent.CasualFrame.Visible = true
        self:ConnectCasualButtons()
    end))
    table.insert(self.connections, self.Location.Card_Solo.MouseButton1Click:Connect(function()
        self:SoloButtonClicked()
    end))
end

function Home:DisconnectButtons(connTab: table?)
    for _, v in pairs(connTab or self.connections) do
        if typeof(v) == "table" then
            self:DisconnectButtons(v)
        else
            v:Disconnect()
        end
    end
    if not connTab then
        self.connections = {}
    end
end

function Home:ConnectBottomButton()
    self:DisconnectBottomButton()
    self.coreconnections.bottomButton = self.Location.Card_Bottom.MouseButton1Click:Connect(function()
        self.var.bottomButtonClickedFunc()
    end)
end

function Home:DisconnectBottomButton()
    if self.coreconnections.bottomButton then
        self.coreconnections.bottomButton:Disconnect()
        self.coreconnections.bottomButton = nil
    end
end

function Home:ConnectCasualButtons()
    local casPage = self.Location.Parent.CasualFrame

    -- disconnect any casual connections jic
    self:DisconnectCasualButtons()

    -- connect back button
    table.insert(self.connections.modes, casPage.Button_Back.MouseButton1Click:Connect(function()
        casPage.Visible = false
        self.Location.Visible = true
        self:DisconnectCasualButtons()
    end))

    -- connect queue buttons
    table.insert(self.connections.modes, casPage.Card_Deathmatch.MouseButton1Click:Connect(function()
        self:QueueButtonClicked(casPage.Card_Deathmatch, "Deathmatch")
    end))

    table.insert(self.connections.modes, casPage.Card_1v1.MouseButton1Click:Connect(function()
        self:QueueButtonClicked(casPage.Card_1v1, "1v1")
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

function Home:DisconnectCasualButtons()
    if self.connections.modes then for _, v in pairs(self.connections.modes) do v:Disconnect() end end
    self.connections.modes = {}
end

-- | Button Clicked |

function Home:BottomClickedLobby_JoinDM()
    if self.var.processing then
        return
    end
    self.var.processing = true
    self.Location.Card_Bottom:SetAttribute("Joined", true)
    local success = RequestSpawnEvent:InvokeServer()
    if success then
        self._closeMain()
        self.Location.Card_Bottom.InfoLabel.Text = LOBBY_BOTTOM_CLICKED_TEXT
        game.Players.LocalPlayer.PlayerScripts.MainMenu.events.connectOpenInput:Fire()
    end
    self.var.processing = false
end

function Home:BottomClickedLobby_LeaveDM()
    if self.var.processing then
        return
    end
    self.var.processing = true
    local success = RequestDeathEvent:InvokeServer()
    if success then
        self:SetMenuType("Lobby")
        self.Location.Card_Bottom.InfoLabel.Text = LOBBY_BOTTOM_DEFAULT_TEXT
        self.Location.Card_Bottom:SetAttribute("Joined", false)
        task.delay(0.2, function()
            game:GetService("UserInputService").MouseIconEnabled = true
        end)
    end

    self.var.processing = false
end

function Home:SoloButtonClicked()
    self.Location.Visible = false
    self.Location.Parent.SoloPopupRequest.Visible = true

    local processing = false
    local connections
    connections = {
        self.Location.Parent.SoloPopupRequest.Card_Stable.MouseButton1Click:Once(function()
            if processing then
                return
            end
            processing = true
            Popup.burst("Teleporting!", 3)
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Location.Visible = true

            RequestQueueEvent:InvokeServer("TeleportPrivateSolo", "Stable")
            connections[2]:Disconnect()
            connections[1]:Disconnect()
        end),
        --[[self.Location.Parent.SoloPopupRequest.Card_Unstable.MouseButton1Click:Once(function()
            connections[1]:Disconnect()
            connections[3]:Disconnect()
            Popup.burst("Teleporting!", 3)
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Location.Visible = true

            RequestQueueEvent:InvokeServer("TeleportPrivateSolo", "Unstable")
            connections[2]:Disconnect()
        end),]]
        self.Location.Parent.SoloPopupRequest.Card_Cancel.MouseButton1Click:Once(function()
            if processing then
                return
            end
            processing = true
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Location.Visible = true
            self._playSoloDebounce = false
            connections[1]:Disconnect()
            connections[2]:Disconnect()
        end)
    }
end

function Home:QueueButtonClicked(card, queue)
    if self.var.nextClickAllow > tick() then Popup.burst("Wait a second before requesting!", 1) return end
    self.var.nextClickAllow = tick() + CLICK_DEBOUNCE

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

-- | Gamemodes |

function Home:SetMenuType(menuType: string)
    local main = self._main
    self.var.currentMenuType = menuType

    if menuType == "Lobby" then
        main.disconectOpenInput()
        if not main.var.opened and not main.var.loading then
            main.open()
        end
        self.Location.Card_Bottom.InfoLabel.Text = LOBBY_BOTTOM_DEFAULT_TEXT
        self.var.bottomButtonClickedFunc = function()
            if self.Location.Card_Bottom:GetAttribute("Joined") then
                self:BottomClickedLobby_LeaveDM()
            else
                self:BottomClickedLobby_JoinDM()
            end
        end
    elseif menuType == "Game" then
        main.conectOpenInput()
        self.Location.Card_Bottom.InfoLabel.Text = GAME_BOTTOM_DEFAULT_TEXT
        self.var.bottomButtonClickedFunc = function()
            self._closeMain()
            RequestQueueEvent:InvokeServer("TeleportPublicSolo", "Lobby")
            self.coreconnections.bottomButton:Disconnect()
        end
    end

    self:DisconnectBottomButton()
    self:ConnectBottomButton()
end

return Home