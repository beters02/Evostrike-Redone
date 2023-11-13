local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local PlayerData = require(Framework.Module.PlayerData)

local Shop = {}

function Shop:init()
    self = setmetatable(Shop, self)
    self.Player = game.Players.LocalPlayer

    local owned = self.Location:WaitForChild("OwnedFrame")
    self.pcLabel = owned:WaitForChild("PremiumCreditAmountLabel")
    self.scLabel = owned:WaitForChild("StrafeCoinAmountLabel")
    
    self.core_connections = {}
    self.button_connections = {}
    self:ConnectCore()

    local sc, pc = self:GetEconomy()
    self:Update(sc, pc)
    return self
end

--

function Shop:Open()
    self:OpenAnimations()
    self:ConnectButtons()
end

function Shop:Close()
    self.Location.Visible = false
    self:DisconnectButtons()
end

function Shop:GetEconomy() --: sc, pc
    local pd = PlayerData:Get()
    return pd.economy.strafeCoins, pd.economy.premiumCredits
end

function Shop:Update(sc: number?, pc: number?)
    if sc then
        self.scLabel.Text = tostring(sc)
    end
    if pc then
        self.pcLabel.Text = tostring(pc)
    end
end

function Shop:ConnectCore()
    self.core_connections.sc = PlayerData:PathValueChanged("economy.strafeCoins", function(new)
        self:Update(new)
    end)
    self.core_connections.pc = PlayerData:PathValueChanged("economy.premiumCredits", function(new)
        self:Update(false, new)
    end)
end

function Shop:ConnectButtons()
    for _, skinFrame in pairs(self.Location:GetChildren()) do
        if skinFrame.Name == "SkinContentFrame" then
            for _, weaponFrame in pairs(skinFrame:GetChildren()) do
                if not weaponFrame:IsA("Frame") or not string.match(weaponFrame.Name, "Weapon") then
                    return
                end

                local str = skinFrame.Name .. "_" .. weaponFrame.Name
                local img = weaponFrame:WaitForChild("ImageButton")
                self.button_connections[str] = img.MouseButton1Click:Connect(function()
                    self:PurchaseClick(skinFrame:GetAttribute("SkinName"), weaponFrame.Name)
                end)
            end
        end
    end
end

function Shop:DisconnectButtons()
    for _, v in pairs(self.button_connections) do
        v:Disconnect()
    end
    self.button_connections = {}
end

--

function Shop:PurchaseClick(skin, weapon)
    
end

return Shop