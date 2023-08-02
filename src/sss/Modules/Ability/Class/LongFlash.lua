local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityObjects = ReplicatedStorage:WaitForChild("Objects"):WaitForChild("Ability"):WaitForChild("LongFlash")

local LongFlash = {

    -- flash settings
    isGrenade = true,
    acceleration = 10,
    speed = 150,
    gravityModifier = 0.5,
    anchorTime = 0.2,
    anchorDistance = 5,
    popTime = 0.3,
    blindLength = 1.5,
    canSeeAngle = 1.07,
    flashGui = AbilityObjects:WaitForChild("FlashbangGui"),
    flashEmitter = AbilityObjects:WaitForChild("Emitter"),

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

function LongFlash:Use()
    -- long flash does CanUse on the server via remoteFunction: ThrowGrenade
    local hit = LongFlash.player:GetMouse().Hit
    local used = LongFlash.remoteFunction:InvokeServer("ThrowGrenade", hit)
    if used then
        self.uses -= 1
    end
end

if game:GetService("RunService"):IsServer() then
    
    local function canSee(player, bullet)
        return ReplicatedStorage.Remotes.Ability.Get:InvokeClient(player, "CanSee", bullet)
    end

    local function FlashPop(bullet)
        for i, v in pairs(Players:GetPlayers()) do
            local see = canSee(v, bullet)
            print(see)
            if not see then continue end
            
            -- check if flash can hit player
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {workspace.Temp, workspace.MovementIgnore}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(bullet.Position, (v.Character:WaitForChild("HumanoidRootPart").Position - bullet.Position).Unit * 150, params)
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

                local fadeInTween = TweenService:Create(gui.FlashedFrame, TweenInfo.new(0.3), {Transparency = 0}) 
                fadeInTween:Play()

                local fadeOutTween = TweenService:Create(gui.FlashedFrame, TweenInfo.new(0.2), {Transparency = 1})
                local cFadeTween = TweenService:Create(c, TweenInfo.new(0.25), {Rate = 0})

                task.delay(LongFlash.blindLength, function()		 
                    fadeOutTween:Play()
                    cFadeTween:Play()
                    task.spawn(function()
                        cFadeTween.Completed:Wait()
                        cFadeTween:Destroy()
                    end)
                    Debris:AddItem(gui, 0.5)
                end)
            end)
        end
    end

    function LongFlash.RayHit(cast, result, velocity, bullet, playerLookNormal)
        local normal = result.Normal
        local outDistance = LongFlash.anchorDistance
        animated = true
        task.spawn(function()
            local pos = bullet.Position + (normal * outDistance)
            local collRes = workspace:Raycast(bullet.Position, normal * outDistance)
            if collRes then pos = collRes.Position end
            local t = game:GetService("TweenService"):Create(bullet, TweenInfo.new(LongFlash.anchorTime), {Position = pos})
            t:Play()
            t.Completed:Wait()
            bullet.Anchored = true
            task.wait(LongFlash.popTime)
            FlashPop(bullet)
            bullet:Destroy()
            animated = false
        end)
    end

end


return LongFlash