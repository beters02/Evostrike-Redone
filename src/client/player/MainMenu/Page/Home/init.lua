--[[TODO
    Keep engineering the Join/Leave Queue Solution
]]

-- CONFIG
local QUEUE_TEXT_FADE_TIME = 0.37
local LOBBY_BOTTOM_DEFAULT_TEXT = "JOIN DEATHMATCH"
local LOBBY_BOTTOM_CLICKED_TEXT = "LEAVE DEATHMATCH"
local GAME_BOTTOM_DEFAULT_TEXT = "GO TO LOBBY"
local BUTTON_HOVER_COLOR = Color3.fromRGB(57, 120, 125) -- 73, 155, 161
local BUTTON_DEFAULT_COLOR = Color3.fromRGB(57, 62, 66)
local PAGE_BUTTON_ENUM = {"Card_Solo", "Card_Join"} -- and MainButtons
local BUTTON_HOVER_FADE_IN_LENGTH = 0.4
local BUTTON_HOVER_FADE_OUT_LENGTH = 0.3
local BUTTON_HOVER_EASING_STYLE = Enum.EasingStyle.Cubic
local BUTTON_HOVER_EASING_DIRECTION = Enum.EasingDirection.Out

local EQUALIZE_BUTTON_TEXT_SIZE = false
--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Queuer = require(script:WaitForChild("Queuer"))
local Popup = require(script.Parent.Parent.Popup)
local Math = require(Framework.Module.lib.fc_math)

local LoadingUI = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("LoadingUI"))

local RequestQueueEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("requestQueueFunction")
local RequestSpawnEvent = ReplicatedStorage.Services.GamemodeService2.RequestSpawn
local RequestDeathEvent = ReplicatedStorage.Services.GamemodeService2.RequestDeath

local Page = require(script.Parent)
local HomePage = setmetatable({}, Page)
HomePage.__index = HomePage

function HomePage.new(mainMenu, frame)
    local self = setmetatable(Page.new(mainMenu, frame), HomePage)
    self.Player = game.Players.LocalPlayer
    self.SoloButton = self.Frame:WaitForChild("Card_Solo")
    self.CasualButton = self.Frame:WaitForChild("Card_Casual")

    self.SoloPopupRequest = self.Main.Gui:WaitForChild("SoloPopupRequest") --todo: chnge name to SoloFrame
    self.SoloStableButton = self.SoloPopupRequest:WaitForChild("Card_Stable")
    self.SoloCancelButton = self.SoloPopupRequest:WaitForChild("Card_Cancel")

    self.CasualFrame = self.Frame.Parent:WaitForChild("CasualFrame")
    self.CasualBackButton = self.CasualFrame:WaitForChild("Button_Back")
    self.Casual1v1Button = self.CasualFrame:WaitForChild("Card_1v1")

    self.InventoryButton = self.Frame:WaitForChild("MainButton_Inventory")
    self.OptionsButton = self.Frame:WaitForChild("MainButton_Options")
    self.StatsButton = self.Frame:WaitForChild("MainButton_Stats")
    self.BottomButton = self.Frame:WaitForChild("Card_Bottom")
    self.JoinButton = self.Frame:WaitForChild("Card_Join")

    -- BottomButtonCallback changes depending on the MenuType.
    self.BottomButtonCallback = joinGameButtonClicked
    self.ActionProcessing = false

    self.MainButtons = {}
    for _, v in pairs(frame:GetChildren()) do
        if string.match(v.Name, "MainButton") or v.Name == "Card_Bottom" then
            self.MainButtons[string.gsub(v.Name, "MainButton_", "")] = v
        end
    end

    self.Tweens = {
        Connections = {},
        QueueTextFadeOut = TweenService:Create(self.Casual1v1Button.InQueueText.TextLabel, TweenInfo.new(QUEUE_TEXT_FADE_TIME, Enum.EasingStyle.Cubic), {TextTransparency = 1}),
        QueueTextFadeIn = TweenService:Create(self.Casual1v1Button.InQueueText.TextLabel, TweenInfo.new(QUEUE_TEXT_FADE_TIME, Enum.EasingStyle.Cubic), {TextTransparency = 0})
    }

    initAllButtonHoverTweens(self)

    return self
end

function HomePage:Open()
    self._Open()
    self.Main:CloseTopBar()
    if self.SoloPopupRequest.Visible then
        self.SoloPopupRequest.Visible = false
    end
    if self.CasualFrame.Visible then
        self.CasualFrame.Visible = false
    end
end

function HomePage:Close()
    self._Close()
    self.Main:OpenTopBar()
end

function HomePage:Connect()
    self:AddConnection("SoloButton", self.SoloButton.MouseButton1Click:Connect(function()
        self.Main:PlayButtonSound("Select1")
        soloMainButtonClicked(self)
    end))
    self:AddConnection("CasualButton", self.CasualButton.MouseButton1Click:Connect(function()
        self.Main:PlayButtonSound("Select1")
        casualMainButtonClicked(self)
    end))
    self:AddConnection("BottomButton", self.BottomButton.MouseButton1Click:Connect(function()
        self.Main:PlayButtonSound("Select1")
        self.BottomButtonCallback(self)
    end))
    self:AddConnection("JoinButton", self.JoinButton.MouseButton1Click:Connect(function()
        self.Main:PlayButtonSound("Select1")
        self.BottomButtonCallback(self)
    end))
    connectSingleButtonHoverTweens(self)
    connPageMainButtons(self)
    connEqualizeButtonText(self)
end

function HomePage:MenuTypeChanged(newMenuType)
    print('ASDJKAHSD:AKLND')
    if newMenuType == "Lobby" then
        self.BottomButton.InfoLabel.Text = LOBBY_BOTTOM_DEFAULT_TEXT
        self.BottomButtonCallback = joinGameButtonClicked
    else
        self.BottomButton.InfoLabel.Text = GAME_BOTTOM_DEFAULT_TEXT
        self.BottomButtonCallback = teleportBackToLobbyButtonClicked
    end
end

--
--
--

-- [[ BUTTON HOVER FUNCTIONALITY ]]

function initAllButtonHoverTweens(self)
    self.HoverButtons = {}
    self.ButtonHoverTweens = {In = {}, Out = {}}
    self.ButtonHoverInTweenInfo = TweenInfo.new(BUTTON_HOVER_FADE_IN_LENGTH, BUTTON_HOVER_EASING_STYLE, BUTTON_HOVER_EASING_DIRECTION)
    self.ButtonHoverOutTweenInfo = TweenInfo.new(BUTTON_HOVER_FADE_OUT_LENGTH, BUTTON_HOVER_EASING_STYLE, BUTTON_HOVER_EASING_DIRECTION)
    for _, str in pairs(PAGE_BUTTON_ENUM) do
        initSingleButtonHoverTweens(self, self.Frame[str])
        table.insert(self.HoverButtons, self.Frame[str])
    end
    for _, button in pairs(self.MainButtons) do
        initSingleButtonHoverTweens(self, button)
        table.insert(self.HoverButtons, button)
    end
end

function initSingleButtonHoverTweens(self, button)
    self.ButtonHoverTweens.In[button.Name] = TweenService:Create(button, self.ButtonHoverInTweenInfo, {BackgroundColor3 = BUTTON_HOVER_COLOR})
    self.ButtonHoverTweens.Out[button.Name] = TweenService:Create(button, self.ButtonHoverOutTweenInfo, {BackgroundColor3 = BUTTON_DEFAULT_COLOR})
end

function playHoverTween(self, button, tween: string)
    local inTween = self.ButtonHoverTweens.In[button.Name]
    local outTween = self.ButtonHoverTweens.Out[button.Name]
    
    if string.lower(tween) == "in" then
        if outTween.PlaybackState == Enum.PlaybackState.Playing then
            outTween:Pause()
        end
        inTween:Play()
    else
        if inTween.PlaybackState == Enum.PlaybackState.Playing then
            inTween:Pause()
        end
        outTween:Play()
    end
end

function connectSingleButtonHoverTweens(self)
    for _, v in pairs(self.HoverButtons) do
        self.Connections["HoverIn_" .. v.Name] = v.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                playHoverTween(self, v, "in")
			end
        end)
        self.Connections["HoverOut_" .. v.Name] = v.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                playHoverTween(self, v, "out")
			end
        end)
    end
end

function stopAllHoverTweens(self)
    for _, v in pairs(self.HoverButtons) do
        self.ButtonHoverTweens.In[v.Name]:Cancel()
        self.ButtonHoverTweens.Out[v.Name]:Cancel()
        v.BackgroundColor3 = BUTTON_DEFAULT_COLOR
    end
end

--

-- Opens "SoloPopupRequest" page, connects more buttons.
function soloMainButtonClicked(self)
    if self.SoloPopupRequest.Visible then
        return
    end
    self.Frame.Visible = false
    self.SoloPopupRequest.Visible = true
    local processingDebounce = false

    -- Confirm the teleport
    self:AddConnection("SoloStableButton", self.SoloStableButton.MouseButton1Click:Once(function()
        if processingDebounce then return end
        processingDebounce = true
        Popup.new(self.Player, "Teleporting!", 3)
        self.SoloPopupRequest.Visible = false
        self.Frame.Visible = true
        RequestQueueEvent:InvokeServer("TeleportPrivateSolo", "Stable")
        self.Connections.SoloCancelButton:Disconnect()
        self.Connections.SoloStableButton:Disconnect()
        processingDebounce = nil
    end))

    -- Cancel the teleport
    self:AddConnection("SoloCancelButton", self.SoloCancelButton.MouseButton1Click:Connect(function()
        if processingDebounce then return end
        processingDebounce = true
        self.SoloPopupRequest.Visible = false
        self.SoloPopupRequest.Visible = false
        self.Frame.Visible = true
        self.Connections.SoloStableButton:Disconnect()
        self.Connections.SoloCancelButton:Disconnect()
        processingDebounce = nil
    end))
end

-- Opens "Casual Page", connects more buttons.
function casualMainButtonClicked(self)
    self.Frame.Visible = false
    self.CasualFrame.Visible = true

    -- Queue for 1v1
    self:AddConnection("Casual1v1Button", self.CasualBackButton.MouseButton1Click:Connect(function()
        self.Main:PlayButtonSound("Select1")
        casualQueueButtonClicked(self)
    end))

    -- Go back to Home Page
    self:AddConnection("CasualBackButton", self.CasualBackButton.MouseButton1Click:Connect(function()
        self.Main:PlayButtonSound("Select1")
        self.Frame.Visible = true
        self.CasualFrame.Visible = false
        self.Connections.Casual1v1Button:Disconnect()
        self.Connections.CasualBackButton:Disconnect()
    end))
end

function casualQueueButtonClicked(self)
    if not Queuer.IsInQueue then
        addPlayerToQueue(self)
    else
        removePlayerfromQueue(self)
    end
end

function connPageMainButtons(self)
    for i, v in pairs(self.MainButtons) do
        if v.Name == "Card_Bottom" or v.Name == "Card_Join" then
            continue
        end
        self:AddConnection(i.."Button", v.MouseButton1Click:Connect(function()
            self.Main:PlayButtonSound("Select1")
            pageMainButtonClicked(self, i)
            stopAllHoverTweens(self)
        end))
    end
end

-- Opens other MainMenu Page
function pageMainButtonClicked(self, name)
    self.Main:OpenPage(name)
end

function teleportBackToLobbyButtonClicked(self)
    if self.ActionProcessing then return end
    self.ActionProcessing = true
    self.Main:Close()
    RequestQueueEvent:InvokeServer("TeleportPublicSolo", "Lobby")
    self.ActionProcessing = false
end

function joinGameButtonClicked(self)
    print('CLICKED!')

    if self.ActionProcessing then return end
    self.ActionProcessing  = true

    local card = self.Frame.Card_Bottom
    if card:GetAttribute("Joined") then
        --leaveGame(card)
    else
        joinGame(self, card)
    end

    self.ActionProcessing = false
end

function joinGame(self, button)
    local loadingTime = tick()
    local loading = LoadingUI.new()

    task.wait()
    self.Main:Close()

    local success = RequestSpawnEvent:InvokeServer()
    --[[local ct = tick()
    loadingTime = ct - loadingTime
    print(loadingTime)
    if loadingTime < 5 then
        repeat
            loadingTime = tick() - ct
            task.wait()
            print(loadingTime)
        until loadingTime >= 5
    end]]

    loading:destroy()
    if success then
        self.Frame.Card_Bottom:SetAttribute("Joined", true)
        self.Main:Close()
        button.InfoLabel.Text = LOBBY_BOTTOM_CLICKED_TEXT
        --TODO: make it so you can open menu
    else
        --self.Main:Open()
    end
end

function leaveGame(button)
    local success = RequestDeathEvent:InvokeServer()
    if success then
        button.InfoLabel.Text = LOBBY_BOTTOM_DEFAULT_TEXT
        button:SetAttribute("Joiend", false)
        task.delay(0.2, function()
            game:GetService("UserInputService").MouseIconEnabled = true
        end)
        --TODO: make it so you cannot open the menu
    end
end

function addPlayerToQueue(self)
    changeQueueText(self, "JOINING QUEUE...")

    local success = Queuer.Join()
    if success then
        changeQueueText(self, "LOOKING FOR GAME")
        --Popup "Added to queue"
    else
        changeQueueText(self, "COULD NOT JOIN QUEUE, PLEASE TRY AGAIN", 3)
    end
end

function removePlayerfromQueue(self)
    changeQueueText(self, "LEAVING QUEUE...")
    Queuer.Leave()
    changeQueueText(self, "SUCCESSFULLY LEFT QUEUE", 3)
end

function changeQueueText(self, new, toggleLength: number?) -- if toggleLength, text will disappear after set time
    local label = self.Casual1v1Button.InQueueText.TextLabel
    local outTween = self.Tweens.QueueTextFadeOut
    local inTween  = self.Tweens.QueueTextFadeIn

    if outTween.PlaybackState == Enum.PlaybackState.Playing then
        outTween:Pause()
    elseif inTween.PlaybackState == Enum.PlaybackState.Playing then
        inTween:Cancel()
    end

    for _, v in pairs(self.Tweens.Connections) do
        v:Disconnect()
    end

    table.insert(self.Tweens.Connections, outTween.Completed:Once(function()
        label.Text = new
        inTween:Play()
    end))

    if toggleLength then
        table.insert(self.Tweens.Connections, inTween.Completed:Once(function()
            task.wait(toggleLength)
            outTween:Play()
        end))
    end

    outTween:Play()
end

function connEqualizeButtonText(self)

    if EQUALIZE_BUTTON_TEXT_SIZE then
        local lastFrameSize = 0
        self:AddConnection("EqualizeSize", RunService.RenderStepped:Connect(function()
            local invsize = self.InventoryButton.InfoLabel.Size.Y.Scale
            invsize = Math.scaleToOffsetNumber(false, invsize).Y
            if lastFrameSize ~= invsize then
                lastFrameSize = invsize
                scaleTopBarFrames(self, self.InventoryButton)
            end
        end))
    end
    
end

function scaleTopBarFrames(self, titleFrame)
    local scsz = titleFrame.Size.Y.Scale * titleFrame.InfoLabel.Size.Y.Scale
	local size = Math.scaleToOffsetNumber(false, scsz).Y / 2
    size = math.floor(size)

    for _, v in pairs(self.MainButtons) do
        v.InfoLabel.TextScaled = false
        v.InfoLabel.TextSize = size
    end
end

return HomePage