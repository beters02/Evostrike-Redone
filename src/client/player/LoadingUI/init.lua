--[[
    Main Module for loading and requesting Loading Screens.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Events = script:WaitForChild("Events")

-- CONFIG [[
    local LD_TXT_INTERVAL = .5
    local LD_BG_INTERVAL = 2
    local LD_BG_RESIZE = 300 -- resize X resize
    local END_FADEOUT_LENGTH = 1
--]]

-- ASSETS [[
    local loadingScreenGui = Assets:WaitForChild("UI").LoadingScreenGui
--]]

-- Loading Gui Functions
local function createLoadingGui(parent)
    local x = loadingScreenGui:Clone()
    x.Parent = parent or ReplicatedStorage
    return x
end

local function recurseLoadAnim(self)
    if self.twns.loadBG1 then
        self.twns.loadBG1:Destroy()
    end
    if self.twns.loadBG2 then
        self.twns.loadBG2:Destroy()
    end

    local currBG = self.ui.BG.BGImage
    local editableImage = AssetService:CreateEditableImageAsync(currBG.Image)
    editableImage.Parent = currBG
    self.loadValue.Value = editableImage.Size.X
    self.twns.loadBG1 = TweenService:Create(self.loadValue, TweenInfo.new(LD_BG_INTERVAL), {Value = LD_BG_RESIZE})
    self.twns.loadBG2 = TweenService:Create(currBG, TweenInfo.new(LD_BG_INTERVAL), {ImageTransparency = 1, BackgroundTransparency = 1})

    if self.conn.updateBG then
        self.conn.updateBG:Disconnect()
        self.conn.updateBG = nil
    end
    self.conn.updateBG = RunService.RenderStepped:Connect(function()
        editableImage:Resize(Vector2.new(self.loadValue.Value, self.loadValue.Value))
    end)

    self.twns.loadBG1:Play()
    self.twns.loadBG1.Completed:Wait()

    self.conn.updateBG:Disconnect()
    self.conn.updateBG = nil

    local newBG = loadingScreenGui.BG.BGImage:Clone()
    task.wait()
    newBG.Parent = self.ui.BG

    self.twns.loadBG2:Play()
    self.twns.loadBG2.Completed:Wait()

    currBG:Destroy()
    print('new!')

    recurseLoadAnim(self)
end

local Loading = {}
Loading.__index = Loading

function Loading.new()
    local self = setmetatable({}, Loading)
    self.txt = "LOADING"
    self.ui = createLoadingGui(game.Players.LocalPlayer.PlayerGui)
    self.lbl = self.ui:WaitForChild("MainFrame").Label.TextLabel
    self.lbl.Text = self.txt

    self.tasks = {}

    self.twns = {}
    self.twns.fadeOutTextLbl = TweenService:Create(self.lbl, TweenInfo.new(END_FADEOUT_LENGTH), {TextTransparency = 1})
    self.twns.fadeOutTextStroke = TweenService:Create(self.lbl:WaitForChild("UIStroke"), TweenInfo.new(END_FADEOUT_LENGTH), {Transparency = 1})
    self.twns.fadeOutBG = TweenService:Create(self.ui:WaitForChild("BG").BGImage, TweenInfo.new(END_FADEOUT_LENGTH), {ImageTransparency = 1})

    self.conn = {}
    self.connected = false
    --[[self:connect()
    self:playLoadingAnimation()]]
    return self
end

function Loading:connect()
    --[[if self.connected then
        return
    end
    self.connected = true

    local timer = 0
    local dots = 1
    self.conn.ldtxt = RunService.RenderStepped:Connect(function(dt)
        timer += dt
        if timer >= LD_TXT_INTERVAL then
            timer = 0
            dots += 1

            if dots >= 4 then
                dots = 0
            end

            local txt = "LOADING" .. string.rep(".", dots)
            self.lbl.Text = txt
            print(txt)
        end
    end)]]
end

function Loading:playLoadingAnimation()
    self.loadValue = Instance.new("NumberValue", ReplicatedStorage)
    self.loadValue.Name = "LoadingIntervalValue"

    self.tasks.loadBG = task.spawn(function()
        recurseLoadAnim(self)
    end)
end

function Loading:playEndAnimation()
    self.twns.fadeOutTextLbl:Play()
    self.twns.fadeOutTextStroke:Play()
    self.twns.fadeOutBG:Play()
    task.wait(END_FADEOUT_LENGTH)
end

function Loading:destroy()
    for _, v in pairs(self.conn) do
        v:Disconnect()
    end

    -- animation
    --self:playEndAnimation()

    --coroutine.close(self.tasks.loadBG)

    self.ui:Destroy()
    self = nil
end

-- Server Functions
function Loading:RequestLoadingScreen(plr)
    return Events.Request:InvokeClient(plr, "Request")
end

function Loading:EndLoadingScreen(plr)
    return Events.Request:InvokeClient(plr, "End")
end

-- Server Connections

-- Client Connections
if RunService:IsClient() then

    local currentUi = false
    Events:WaitForChild("Request").OnClientInvoke = function(action)
        if action == "Gui" then
            if currentUi then
                currentUi:destroy()
                currentUi = nil
            end
            currentUi = Loading.new()
            return true
        elseif action == "End" then
            if not currentUi then
                return
            end
            currentUi:destroy()
            return true
        end
    end
end

return Loading