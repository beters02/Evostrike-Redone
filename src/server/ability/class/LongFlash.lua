local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AbilityObjects = ReplicatedStorage:WaitForChild("ability"):WaitForChild("obj"):WaitForChild("LongFlash")
local Tables = require(Framework.Module.lib.fc_tables)
local BotService
if RunService:IsServer() then
    BotService = require(ReplicatedStorage:WaitForChild("Services"):WaitForChild("BotService"))
end

local LongFlash = {
    name = "LongFlash",
    isGrenade = true,

    -- general settings
    cooldownLength = 7,
    uses = 100,
    usingDelay = 1, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time

    -- useage
    grenadeThrowDelay = 0.2,

    -- grenade
    acceleration = 10,
    speed = 150,
    gravityModifier = 0.2,
    startHeight = 2,

    -- animation / holding
    clientGrenadeSize = nil,
    grenadeVMOffsetCFrame = CFrame.Angles(0,math.rad(80),0) + Vector3.new(0, 0, 0.4), -- if you have a custom animation already, set this to nil
    throwAnimFadeTime = 0.18,
    throwFinishSpringShove = Vector3.new(-0.4, -0.5, 0.2),

    -- flash settings
    anchorTime = 0.2,
    anchorDistance = 5,
    popTime = 0.3,
    blindLength = 1.5,
    canSeeAngle = 1.07,
    flashGui = AbilityObjects:WaitForChild("FlashbangGui"),
    flashEmitter = AbilityObjects:WaitForChild("Emitter"),

    -- absr = Absolute Value Random
    -- rtabsr = Random to Absolute Value Random
    useCameraRecoil = {
        downDelay = 0.07,

        up = 0.02,
        side = 0.008,
        shake = "0.015-0.035rtabsr",

        speed = 4,
        force = 60,
        damp = 4,
        mass = 9
    },

    -- data settings
    abilityName = "LongFlash",
    inventorySlot = "secondary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
    remoteEvent = nil,
}

--[[
    FlashPop
]]

function LongFlash.FlashPop(grenadeModel)

    local players = Tables.combine(Players:GetPlayers(), BotService:GetBots())

    --if not RunService:IsServer() then end -- Unneccssary since it wont be called on client
    for i, v in pairs(players) do
        local isBot = true
        if Players:FindFirstChild(v.Name) then
            isBot = false
            if not v.Character then continue end
            local see = LongFlash.CanSee(v, grenadeModel)
            if not see then continue end
        end

        -- check if flash can hit player (wall collision)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {workspace.Temp, workspace.MovementIgnore}
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.CollisionGroup = "Bullets"
        local result = workspace:Raycast(grenadeModel.Position, ((v.Character:WaitForChild("Head").CFrame.Position - Vector3.new(0,0,0)) - grenadeModel.Position).Unit * 150, params)

        local resultModel = result and result.Instance:FindFirstAncestorWhichIsA("Model")
        if result and (result.Instance:FindFirstAncestorWhichIsA("Model") ~= v.Character or not string.match(result.Instance.Name, "Head")) then
            print(resultModel)
            continue
        end

        task.spawn(function()

            -- create emitter
            local c = LongFlash.flashEmitter:Clone()
            c.Parent = v.Character.Head
            c.Enabled = true

             -- gui responsible for "blinding" the player
            if not isBot then
                local gui = LongFlash.flashGui:Clone()
                gui.FlashedFrame.Transparency = 1
                gui.Parent = v.PlayerGui
                -- create and play player blinded tweens
                local fadeInTween = TweenService:Create(gui.FlashedFrame, TweenInfo.new(0.3), {Transparency = 0}) 
                fadeInTween:Play()

                local fadeOutTween = TweenService:Create(gui.FlashedFrame, TweenInfo.new(0.2), {Transparency = 1})
                local cFadeTween = TweenService:Create(c, TweenInfo.new(0.25), {Rate = 0})
                
                -- fade out tweens
                task.delay(LongFlash.blindLength, function()		 
                    fadeOutTween:Play()
                    cFadeTween:Play()
                    task.spawn(function()
                        cFadeTween.Completed:Wait()
                        cFadeTween:Destroy()
                    end)
                    Debris:AddItem(gui, 0.5) -- destroy gui
                    Debris:AddItem(c, 0.5)
                end)
            else
                local cFadeTween = TweenService:Create(c, TweenInfo.new(0.25), {Rate = 0})
                task.delay(LongFlash.blindLength, function()
                    cFadeTween:Play()
                    task.spawn(function()
                        cFadeTween.Completed:Wait()
                        cFadeTween:Destroy()
                        Debris:AddItem(c, 0.5)
                    end)
                end)
            end
            
        end)
    end
end

function LongFlash.CanSee(player, grenadeModel)
    if not RunService:IsServer() then return end
    return ReplicatedStorage.ability.remote.sharedAbilityRF:InvokeClient(player, "CanSee", grenadeModel)
end


return LongFlash