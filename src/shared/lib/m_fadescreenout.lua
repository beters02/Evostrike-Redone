local TweenService = game:GetService("TweenService")
export type Fade = {
    UI: ScreenGui,

    InLength: number,
    OutLength: number,

    In: Tween,
    Out: Tween,

    Destroy: () -> (),

    OutWrap: () -> () -- Wrap FadeOut and Destroy
}

local function createScreenGui(player)
    local ui = Instance.new("ScreenGui")
    ui.Name = "Fade"
    ui.IgnoreGuiInset = true
    ui.Enabled = true
    ui.ResetOnSpawn = false
    local frame = Instance.new("Frame", ui)
    frame.Size = UDim2.fromScale(1,1)
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = true
    ui.Parent = player.PlayerGui
    return ui
end

return function(player, inLength, outLength)

    inLength = inLength or 1
    outLength = outLength or 1

    local ui = createScreenGui(player)

    local fade: Fade
    fade = {
        UI = ui,

        In = TweenService:Create(ui.Frame, TweenInfo.new(inLength), {BackgroundTransparency = 0}),
        Out = TweenService:Create(ui.Frame, TweenInfo.new(outLength), {BackgroundTransparency = 1}),

        Destroy = function()
            pcall(function() fade.In:Cancel() end)
            pcall(function() fade.Out:Cancel() end)
            if ui then ui:Destroy() end
        end,

        OutWrap = function()
            fade.Out:Play()
            fade.Out.Completed:Once(function()
                fade:Destroy()
            end)
        end
    }

    return fade
end