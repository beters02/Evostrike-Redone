local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local RemotesLib = require(Framework.ReplicatedStorage.Libraries.Remotes)
local AbilityGet = Framework.ReplicatedStorage.Remotes.Ability.Get

-- Store Ability Options for ease of access
local Shared = {}
Shared.AbilityOptions = {}

if RunService:IsClient() then
    Shared.AbilityOptions.LongFlash = require(AbilityGet:InvokeServer("Class", "LongFlash"))
else
    local AbilityClass = Framework.ServerScriptService.Modules.Ability.Class
    Shared.AbilityOptions.LongFlash = require(AbilityClass.LongFlash)
end

--[[
    function InitCaster

    @return caster, castBehavior
]]
function Shared.InitCaster(character, abilityOptions, abilityObjects)
    local FastCast = require(game:GetService("ReplicatedStorage"):WaitForChild("Scripts"):WaitForChild("Libraries"):WaitForChild("FastCastRedux"))
    local caster, casbeh
    caster = FastCast.new()
    casbeh = FastCast.newBehavior()
    casbeh.RaycastParams = RaycastParams.new()
    casbeh.RaycastParams.CollisionGroup = "Bullets"
    casbeh.RaycastParams.FilterDescendantsInstances = {character}
    casbeh.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    casbeh.MaxDistance = 500
    casbeh.Acceleration = Vector3.new(0, -workspace.Gravity * abilityOptions.gravityModifier, 0)
    casbeh.CosmeticBulletContainer = workspace.Temp
    casbeh.CosmeticBulletTemplate = abilityObjects.Models.Grenade
    return caster, casbeh
end

--[[
    function FireCaster
]]

function Shared.FireCaster(player, mouseHit, caster, casbeh, abilityOptions)
    local startLv = player.Character.HumanoidRootPart.CFrame.LookVector
	local origin = player.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, abilityOptions.startHeight, 0)
	local direction = (mouseHit.Position - origin).Unit
    local cast = caster:Fire(origin, direction, direction * abilityOptions.speed, casbeh)
    local bullet = cast.RayInfo.CosmeticBulletObject
    local conns = {}
    table.insert(conns, caster.LengthChanged:Connect(Shared.GrenadeOnLengthChanged))
    table.insert(conns, caster.RayHit:Connect(function(cast, result, velocity, bullet, playerLookNormal)
        if abilityOptions.abilityName == "LongFlash" then
            Shared.LongFlashRayHit(cast, result, velocity, bullet, playerLookNormal)
        end
    end))
    table.insert(conns, caster.CastTerminating:Connect(function()
        for i, v in pairs(conns) do
            v:Disconnect()
        end
    end))
    return bullet, conns
end

--[[
    function GrenadeOnLengthChanged
]]

function Shared.GrenadeOnLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then 
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0, 0, -(length - bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
	end
end

--[[
    function LongFlashRayHit
]]

function Shared.LongFlashRayHit(cast, result, velocity, grenadeModel, playerLookNormal)
    local LongFlash = Shared.AbilityOptions.LongFlash
    local normal = result.Normal
    local outDistance = LongFlash.anchorDistance
    task.spawn(function()
        local pos = grenadeModel.Position + (normal * outDistance)
        local collRes = workspace:Raycast(grenadeModel.Position, normal * outDistance)
        if collRes then pos = collRes.Position end

        -- send grenade out reflected
        local t = game:GetService("TweenService"):Create(grenadeModel, TweenInfo.new(LongFlash.anchorTime), {Position = pos})
        t:Play()
        t.Completed:Wait()

        -- once the grenade has reached its reflection time (anchor time), wait another small amount of times so players can react.
        grenadeModel.Anchored = true
        task.wait(LongFlash.popTime)
        
        -- only register flash popping if server
        if RunService:IsServer() then
            LongFlash.FlashPop(grenadeModel)
        end

        -- destroy bullet after flashpop
        grenadeModel:Destroy()
    end)
end

return Shared