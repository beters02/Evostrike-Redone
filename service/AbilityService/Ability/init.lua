local RunService = game:GetService("RunService")
local AbilityService = game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("AbilityService")

local Ability = {
    Options = {
        name = "Ability",
        inventorySlot = "primary",
        isGrenade = false,
        uses = 100,
        cooldown = 4
    }
}

function Ability.new(player, module)
    local req
    req = setmetatable(require(module), Ability)
    req.new = nil
    if req.Options.isGrenade then
        for i, v in pairs(require(AbilityService:WaitForChild("Ability"):WaitForChild("Grenade"))) do
            req[i] = v
        end
        req.Params = req:GetRaycastParams()
    end
    req.Module = module
    req.Player = player
    req.Animations = {}
    if req.Module:WaitForChild("Assets"):FindFirstChild("Animations") then
        if RunService:IsClient() then
            for _, v in pairs(req.Module.Assets.Animations:GetChildren()) do
                if v.Name == "Server" then
                    for _, s in pairs(v:GetChildren()) do
                        req.Animations.server[v.Name] = req.Player.Humanoid.Animator:LoadAnimation(v)
                    end
                elseif v:IsA("Animation") then
                    req.Animations.client[v.Name] = workspace.CurrentCamera:WaitForChild("viewModel"):WaitForChild("AnimationController"):LoadAnimation(v)
                end
            end
        end
    end
    return req
end

function Ability:Use()
end

return Ability