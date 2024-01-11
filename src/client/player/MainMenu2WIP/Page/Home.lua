--TODO:
-- We may want to Smartly Connect these functions so we dont overrwrite and cause a memory leak.

-- syntax is horribly ugly and long for this lets try to find something nice and new
function smartConnect(current, new)
    if current then
        current:Disconnect()
    end
    return new
end

local Page = require(script.Parent)

local HomePage = setmetatable({}, Page)
HomePage.__index = HomePage

function HomePage.new(mainMenu, frame)
    local self = setmetatable(Page.new(mainMenu, frame), HomePage)
    self.SoloButton = self.Frame:WaitForChild("Card_Solo")
    self.CasualButton = nil

    self.SoloPopupReqest = self.Frame.Parent:WaitForChild("SoloPopupRequest")
    self.SoloStableButton = self.SoloPopupReqest:WaitForChild("Card_Stable")
    self.SoloCancelButton = self.SoloPopupReqest:WaitForChild("Card_Cancel")
end

function HomePage:Connect()

    -- Solo Button
    self.Connections.SoloButton = self.Frame.Card_Solo.MouseButton1Click:Connect(function()
        self.Frame.Visible = false
        self.Frame.Parent.SoloPopupRequest.Visible = true

        local processing = false

        self.Connections.SoloStableButton = self.SoloStableButton.MouseButton1Click:Once(function()
            if processing then
                return
            end
            processing = true
            --Popup.burst("Teleporting!", 3)
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Location.Visible = true

            --RequestQueueEvent:InvokeServer("TeleportPrivateSolo", "Stable")
            self.Connections.SoloCancelButton:Disconnect()
            self.Connections.SoloStableButton:Disconnect()
        end)

        self.Connections.SoloCancelButton = self.SoloCancelButton.MouseButton1Click:Connect(function()
            if processing then
                return
            end
            processing = true
            self.SoloPopupRequest.Visible = false
            self.Location.Parent.SoloPopupRequest.Visible = false
            self.Frame.Visible = true
            self.Connections.SoloStableButton:Disconnect()
            self.Connections.SoloCancelButton:Disconnect()
        end)
    end)
end

return HomePage