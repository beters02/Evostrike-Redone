local TweenService = game:GetService("TweenService")
local DefaultTweenProperties = {time = 1, easingStyle = Enum.EasingStyle.Quad, easingDirection = Enum.EasingDirection.Out, repeatCount = 0, reverses = false, delayTime = 0}

local tween = {}

function tween.New(instance, infoProperties, tweenProperties)
    infoProperties = infoProperties or {}
    for i, v in pairs(DefaultTweenProperties) do
        if not infoProperties[i] then
            infoProperties[i] = v
        end
    end
    return TweenService:Create(
        instance,
        TweenInfo.new(
            infoProperties.time,
            infoProperties.easingStyle,
            infoProperties.easingDirection,
            infoProperties.repeatCount,
            infoProperties.reverses,
            infoProperties.delayTime
        ),
        tweenProperties
    )
end

return tween