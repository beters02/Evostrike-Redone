local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AbilityObjects = ReplicatedStorage:WaitForChild("Objects"):WaitForChild("Ability"):WaitForChild("LongFlash")
local Replicate = ReplicatedStorage.Remotes.Ability.Replicate
local ReplicateBind = ReplicatedStorage.Remotes.Ability.ReplicateBind

local LongFlash = {

    -- flash settings
    isGrenade = true,
    acceleration = 10,
    speed = 150,
    gravityModifier = 0.2,
    anchorTime = 0.2,
    anchorDistance = 5,
    popTime = 0.3,
    blindLength = 1.5,
    canSeeAngle = 1.07,
    flashGui = AbilityObjects:WaitForChild("FlashbangGui"),
    flashEmitter = AbilityObjects:WaitForChild("Emitter"),
    startHeight = 2,

    -- genral settings
    cooldownLength = 3,
    uses = 100,

    -- data settings
    abilityName = "LongFlash",
    inventorySlot = "secondary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
    remoteEvent = nil,
}

--[[
    Use
]]

function LongFlash:Use()

    -- long flash does CanUse on the server via remoteFunction: ThrowGrenade
    local hit = LongFlash.player:GetMouse().Hit
    local used = LongFlash.remoteFunction:InvokeServer("ThrowGrenade", hit)

    -- update client uses
    if used then
        self.uses -= 1
    end
end

--[[
    RayHit (Initial Grenade Bounce)
]]



--[[
    FlashPop
]]

function LongFlash.FlashPop(grenadeModel)
    if not RunService:IsServer() then return end
    for i, v in pairs(Players:GetPlayers()) do
        if not v.Character then continue end
        local see = LongFlash.CanSee(v, grenadeModel)
        print(see)
        if not see then continue end

        -- check if flash can hit player (wall collision)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {workspace.Temp, workspace.MovementIgnore}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(grenadeModel.Position, (v.Character:WaitForChild("HumanoidRootPart").Position - grenadeModel.Position).Unit * 150, params)
        local resultModel = result and result.Instance:FindFirstAncestorWhichIsA("Model")
        if result and result.Instance:FindFirstAncestorWhichIsA("Model") ~= v.Character then
            print(resultModel)
            continue
        end

        task.spawn(function()
             -- gui responsible for "blinding" the player
            local gui = LongFlash.flashGui:Clone()
            gui.FlashedFrame.Transparency = 1
            gui.Parent = v.PlayerGui
            
            -- create emitter
            local c = LongFlash.flashEmitter:Clone()
            c.Parent = v.Character.Head
            c.Enabled = true

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
            end)
        end)
    end
end

function LongFlash.CanSee(player, grenadeModel)
    if not RunService:IsServer() then return end
    return ReplicatedStorage.Remotes.Ability.Get:InvokeClient(player, "CanSee", grenadeModel)
end


return LongFlash