local TweenService = game:GetService("TweenService")
--[[


    page.new(main: MainMenu, basePageTable: )
]]

local DEFAULT_OPEN_LENGTH = 0.7

local pageClass = {}
pageClass.__index = pageClass

function pageClass.new(main, basePageTable, pageName)
    local self = basePageTable._loc:FindFirstChild(pageName) and require(basePageTable._loc[pageName]) or {} -- check if page has it's own class
    self.Name = pageName
    self.Location = main.gui[pageName.."Frame"]
    self._mainPageModule = basePageTable
    self._sendMessageGui = require(basePageTable._loc.Parent.sendMessageGui)
    self._closeMain = main.close

    local soundsFolder = main.gui:WaitForChild("Sounds")
    self._sounds = {Open = soundsFolder:WaitForChild("selectSound"), Hover = soundsFolder:WaitForChild("hoverSound")}

    pageClass.initTweens(self)

    if self.init then self = self:init(main) end
    return setmetatable(self, pageClass)
end

function pageClass:initTweens()
    self._tweens = {open = {}, close = {}}
    for _, v in pairs(self.Location:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("TextButton") then
            local cbg = v.BackgroundTransparency
            local ctg = v.TextTransparency
            local ctsg = v.TextStrokeTransparency

            table.insert(self._tweens.open, {object = v, changes = {"BackgroundTransparency", "TextTransparency", "TextStrokeTransparency"},
            tween = TweenService:Create(v, TweenInfo.new(DEFAULT_OPEN_LENGTH), {BackgroundTransparency = cbg, TextTransparency = ctg, TextStrokeTransparency = ctsg})})

            table.insert(self._tweens.close, {object = v, changes = {"BackgroundTransparency", "TextTransparency", "TextStrokeTransparency"},
            tween = TweenService:Create(v, TweenInfo.new(DEFAULT_OPEN_LENGTH), {BackgroundTransparency = 1, TextTransparency = 1, TextStrokeTransparency = 1})})
        elseif v:IsA("ImageLabel") or v:IsA("ImageButton") then
            local cbg = v.BackgroundTransparency
            local cig = v.ImageTransparency
            table.insert(self._tweens.open, {object = v, changes = {"BackgroundTransparency", "ImageTransparency"},
            tween = TweenService:Create(v, TweenInfo.new(DEFAULT_OPEN_LENGTH), {BackgroundTransparency = cbg, ImageTransparency = cig})})
            table.insert(self._tweens.close, {object = v, changes = {"BackgroundTransparency", "ImageTransparency"},
            tween = TweenService:Create(v, TweenInfo.new(DEFAULT_OPEN_LENGTH), {BackgroundTransparency = 1, ImageTransparency = 1})})
        elseif v:IsA("Frame") then
            local cbg = v.BackgroundTransparency
            table.insert(self._tweens.open, {object = v, changes = {"BackgroundTransparency"}, tween = TweenService:Create(v, TweenInfo.new(DEFAULT_OPEN_LENGTH), {BackgroundTransparency = cbg})})
            table.insert(self._tweens.close, {object = v, changes = {"BackgroundTransparency"}, tween = TweenService:Create(v, TweenInfo.new(DEFAULT_OPEN_LENGTH), {BackgroundTransparency = 1})})
        end
    end
end

function pageClass:Open()
    self:OpenAnimations()
end

function pageClass:Close()
    self.Location.Visible = false
end

function pageClass:OpenAnimations()
    self.Location.Visible = true
    self:PlaySound("Open")
    for _, v in pairs(self._tweens.open) do
        for _, c in pairs(v.changes) do
            v.object[c] = 1
        end

        v.tween:Play()
    end
end

function pageClass:CloseAnimations()
    for _, v in pairs(self._tweens.close) do
        v.tween:Play()
    end
end

function pageClass:PlaySound(sound: "Open" | "Hover")
    self._sounds[sound]:Play()
end

function pageClass:FindPage(pageName)
    return self._mainPageModule:FindPage(pageName)
end

return pageClass