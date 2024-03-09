--[[ CONFIGURATION ]]
local FADE_IN_LENGTH = 2 -- maybe send this from gamemode
local POST_MAP_CAMERA_CF_POS = CFrame.new(Vector3.new(532.239, 275.639, 166.093))
local POST_MAP_CAMERA_CF_ROT = CFrame.fromOrientation(math.rad(-2.55), math.rad(-90.326), math.rad(0))
local POST_MAP_CAMERA_CF = POST_MAP_CAMERA_CF_POS * POST_MAP_CAMERA_CF_ROT

--[[ SERVICES ]]
local TweenService = game:GetService("TweenService")

-- [[ VAR ]]
local camera = workspace.CurrentCamera
local blackScreen = script:WaitForChild("BlackScreenGui")
local fadeInTi = TweenInfo.new(FADE_IN_LENGTH)

--  [[ TWEENS ]]
local blackTweenIn = TweenService:Create(blackScreen.Frame, fadeInTi, {BackgroundTransparency = 0})
local blackTweenOut = TweenService:Create(blackScreen.Frame, fadeInTi, {BackgroundTransparency = 1})

local GameEnd = {}

function GameEnd:Start()
    blackScreen.Frame.BackgroundTransparency = 1
    blackScreen.Enabled = true
    blackTweenIn:Play()
end

function GameEnd:MoveToMap()

    -- prepare player models to face camera
    for i, v in pairs(workspace.PostGameMap.Models:GetChildren()) do
        v:WaitForChild("HumanoidRootPart")
        v.PrimaryPart.CFrame = CFrame.new(v.PrimaryPart.CFrame.Position) * (POST_MAP_CAMERA_CF_ROT:Inverse())
    end

    if blackTweenIn.PlaybackState == Enum.PlaybackState.Playing then
        blackTweenIn.Completed:Wait()
    end

    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = POST_MAP_CAMERA_CF

    blackTweenOut:Play()
end

return GameEnd