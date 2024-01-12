--[[TODO
    Keep engineering the Join/Leave Queue Solution
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local NetClient = require(Framework.Module.NetClient)
local EvoMM = require(Framework.Module.EvoMMWrapper)

local Page = require(script.Parent)
local HomePage = setmetatable({}, Page)
HomePage.__index = HomePage

function HomePage.new(mainMenu, frame)
    local self = setmetatable(Page.new(mainMenu, frame), HomePage)
    self.SoloButton = self.Frame:WaitForChild("Card_Solo")
    self.CasualButton = self.Frame:WaitForChild("Card_Casual")

    self.SoloPopupReqest = self.Frame.Parent:WaitForChild("SoloPopupRequest") --todo: chnge name to SoloFrame
    self.SoloStableButton = self.SoloPopupReqest:WaitForChild("Card_Stable")
    self.SoloCancelButton = self.SoloPopupReqest:WaitForChild("Card_Cancel")

    self.CasualFrame = self.Frame.Parent:WaitForChild("CasualFrame")
    self.CasualBackButton = self.CasualFrame:WaitForChild("Button_Back")
    self.Casual1v1Button = self.CasualFrame:WaitForChild("Card_1v1")

    self.InventoryButton = self.Frame:WaitForChild("MainButton_Inventory")
    self.OptionsButton = self.Frame:WaitForChild("MainButton_Options")
    self.StatsButton = self.Frame:WaitForChild("MainButton_Stats")

    self.BottomButton = self.Frame:WaitForChild("Card_Bottom")
    -- BottomButtonCallback changes depending on the MenuType.
    self.BottomButtonCallback = joinGameButtonClicked

    self.LastQueueRequest = 0
    self.IsInQueue = false
end

function HomePage:Open()
    self._Open()
    if self.SoloPopupRequest.Visible then
        self.SoloPopupRequest.Visible = false
    end
    if self.CasualFrame.Visible then
        self.CasualFrame.Visible = false
    end
end

function HomePage:Connect()
    self:AddConnection("SoloButton", self.SoloButton.MouseButton1Click:Connect(function()
        soloMainButtonClicked(self)
    end))
    self:AddConnection("CasualButton", self.CasualButton.MouseButton1Click:Connect(function()
        casualMainButtonClicked(self)
    end))
    self:AddConnection("InventoryButton", self.InventoryButton.MouseButton1Click:Connect(function()
        pageMainButtonClicked(self, "Inventory")
    end))
    self:AddConnection("OptionsButton", self.OptionsButton.MouseButton1Click:Connect(function()
        pageMainButtonClicked(self, "Options")
    end))
    self:AddConnection("CasualButton", self.CasualButton.MouseButton1Click:Connect(function()
        pageMainButtonClicked(self, "Casual")
    end))
    self:AddConnection("BottomButton", self.BottomButton.MouseButton1Click:Connect(function()
        self.BottomButtonCallback(self)
    end))
end

function HomePage:MenuTypeChanged(newMenuType)
    if newMenuType == "Lobby" then
        self.BottomButton.Text = "JOIN DEATHMATCH"
        self.BottomButtonCallback = joinGameButtonClicked
    else
        self.BottomButton.Text = "BACK TO LOBBY"
        self.BottomButtonCallback = teleportBackToLobbyButtonClicked
    end
end

-- Opens "SoloPopupRequest" page, connects more buttons.
function soloMainButtonClicked(self)
    if self.SoloPopupRequest.Visible then
        return
    end
    self.Frame.Visible = false
    self.SoloPopupRequest.Visible = true

    local processingDebounce = false
    self:AddConnection("SoloStableButton", self.SoloStableButton.MouseButton1Click:Once(function()
        if processingDebounce then return end
        processingDebounce = true
        soloStableButtonClicked(self)
        processingDebounce = nil
    end))
    self:AddConnection("SoloCancelButton", self.SoloCancelButton.MouseButton1Click:Connect(function()
        if processingDebounce then return end
        processingDebounce = true
        soloCancelButtonClicked(self)
        processingDebounce = nil
    end))
end

function soloStableButtonClicked(self)
    --Popup.burst("Teleporting!", 3)
    self.Location.Parent.SoloPopupRequest.Visible = false
    self.Location.Visible = true
    --RequestQueueEvent:InvokeServer("TeleportPrivateSolo", "Stable")
    self.Connections.SoloCancelButton:Disconnect()
    self.Connections.SoloStableButton:Disconnect()
end

function soloCancelButtonClicked(self)
    self.SoloPopupRequest.Visible = false
    self.Location.Parent.SoloPopupRequest.Visible = false
    self.Frame.Visible = true
    self.Connections.SoloStableButton:Disconnect()
    self.Connections.SoloCancelButton:Disconnect()
end

-- Opens "Casual Page", connects more buttons.
function casualMainButtonClicked(self)
    self.Frame.Visible = false
    self.CasualFrame.Visible = true

    self:AddConnection("Casual1v1Button", self.CasualBackButton.MouseButton1Click:Connect(function()
        casualQueueButtonClicked(self)
    end))
    self:AddConnection("CasualBackButton", self.CasualBackButton.MouseButton1Click:Connect(function()
        casualBackButtonClicked(self)
    end))
end

function casualQueueButtonClicked(self)
    if tick() - self.LastQueueRequest < 2 then
        return false
    end
    self.LastQueueRequest = tick()

    if self.IsInQueue then
        removePlayerfromQueue(self)
    else
        addPlayerToQueue(self)
    end
end

function casualBackButtonClicked(self)
    self.Frame.Visible = true
    self.CasualFrame.Visible = false
    self.Connections.Casual1v1Button:Disconnect()
    self.Connections.CasualBackButton:Disconnect()
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
    local success = NetClient:MakeRequest(function()
        return EvoMM:AddPlayerToQueue(game.Players.LocalPlayer, "1v1")
    end)
    if success then
        self.IsInQueue = true
        --Popup "Added to queue"
    end
end

function removePlayerfromQueue(self)
    local success = NetClient:MakeRequest(function()
        return EvoMM:RemovePlayerFromQueue(game.Players.LocalPlayer)
    end)
    if success then
        self.IsInQueue = false
        --Popup "Removed from queue"
    end
end

return HomePage