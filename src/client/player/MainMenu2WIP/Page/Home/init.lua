--[[TODO
    Keep engineering the Join/Leave Queue Solution
]]

-- CONFIG
local QUEUE_TEXT_FADE_TIME = 0.37
--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Queuer = require(script:WaitForChild("Queuer"))
local Popup = require(script.Parent.Parent.Popup)
local Math = require(Framework.Module.lib.fc_math)

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

    -- BottomButtonCallback changes depending on the MenuType.
    self.BottomButtonCallback = joinGameButtonClicked

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
    connPageMainButtons(self)
    connEqualizeButtonText(self)
end

function HomePage:MenuTypeChanged(newMenuType)
    if newMenuType == "Lobby" then
        self.BottomButton.Text = "JOIN DEATHMATCH"
        self.BottomButtonCallback = joinGameButtonClicked
    else
        self.BottomButton.Text = "LOBBY"
        self.BottomButtonCallback = teleportBackToLobbyButtonClicked
    end
end

--
--
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
        if v.Name == "Card_Bottom" then
            continue
        end
        self:AddConnection(i.."Button", v.MouseButton1Click:Connect(function()
            self.Main:PlayButtonSound("Select1")
            pageMainButtonClicked(self, i)
        end))
    end
end

-- Opens other MainMenu Page
function pageMainButtonClicked(self, name)
    self.Main:OpenPage(name)
end

function teleportBackToLobbyButtonClicked(self)
    
end

function joinGameButtonClicked(self)
    
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