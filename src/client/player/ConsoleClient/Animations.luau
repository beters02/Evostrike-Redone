local TweenService = game:GetService("TweenService")
local Types = require(script.Parent.Types)
local MTweens = {}

local function init_blur(console)
    local cfg = console.cfg
    console._setBlur = function(_, _) end
    if cfg.blur_when_opened then
        local blur = Instance.new("BlurEffect")
        blur.Enabled = false
        blur.Parent = workspace.CurrentCamera
        local blurOpenTween = TweenService:Create(blur, TweenInfo.new(cfg.blur_fade_in_length), {Size = cfg.blur_max_size})
        local blurCloseTween = TweenService:Create(blur, TweenInfo.new(cfg.blur_fade_out_length), {Size = 0})
        console._setBlur = function(_, enabled)
            if enabled then
                blur.Enabled = true
                blurOpenTween:Play()
            else
                blurCloseTween:Play()
            end
        end
        blurCloseTween.Completed:Connect(function()
            if not console.gui.Enabled then
                blur.Enabled = false
            end
        end)
    end
end

local function init_gui_tweens(console)
    console.openTweenObjs = {} -- { instanceName = {open: Tween, close: Tween, instance: Instance, oprop, cprop} }
    for _, instance in pairs(console.gui:GetDescendants()) do
        if string.match(instance.ClassName, "UI") then
            continue
        end

        local v1 = instance.BackgroundTransparency
        local inlen = console.cfg.console_fade_in_length
        local outlen = console.cfg.console_fade_out_length
        local oprop = {BackgroundTransparency = v1}
        local cprop = {BackgroundTransparency = 1}

        if string.match(instance.ClassName, "Text") then
            oprop.TextTransparency = 0
            cprop.TextTransparency = 1
        elseif instance:IsA("ScrollingFrame") then
            local v2 = instance.ScrollBarThickness
            oprop.ScrollBarThickness = v2
            cprop.ScrollBarThickness = 0
            outlen = outlen * 0.75
        end

        console.openTweenObjs[instance.Name] = {
            instance = instance,
            oprop = oprop,
            cprop = cprop,
            open = TweenService:Create(instance, TweenInfo.new(inlen), oprop),
            close = TweenService:Create(instance, TweenInfo.new(outlen), cprop)
        }
    end
end

function MTweens.initOpenTweens(console: Types.CConsole)
    init_blur(console)
    init_gui_tweens(console)
end

function MTweens.playOpenTweens(console: Types.CConsole, open: boolean)
    local tweenObjKey

    if open then
        tweenObjKey = "open"
        console:_setBlur(true)

        for _, obj in pairs(console.openTweenObjs) do
            for prop, v in pairs(obj.cprop) do
                obj[prop] = v
            end
        end
    else
        tweenObjKey = "close"
        console:_setBlur(false)
    end

    for _, obj in pairs(console.openTweenObjs) do
        obj[tweenObjKey]:Play()
    end
end

function MTweens.initTextItemTween(console: Types.CConsole, item)
    local oprop = {TextTransparency = 0}
    local cprop = {TextTransparency = 1}
    console.openTweenObjs[item.Name] = {
        instance = item,
        oprop = oprop,
        cprop = cprop,
        open = TweenService:Create(item, TweenInfo.new(console.cfg.console_fade_in_length), oprop),
        close = TweenService:Create(item, TweenInfo.new(console.cfg.console_fade_out_length), cprop)
    }
end

return MTweens