local RunService = game:GetService("RunService")

local module = {}

function module.IsPlayerGrounded(player: Player): boolean

    -- sanity
    if not player.Character or not player.Character.Humanoid
    or player.Character.Humanoid.Health <= 100 then return end

    -- var
    local char = player.Character
    local collider = char.HumanoidRootPart or char:WaitForChild("HumanoidRootPart")
    local params = RaycastParams.new()
    local dec = {player.Character}
    local raydis = 5

    -- grab movement options from movement script if client
    -- also ignore camera descendants
    if RunService:IsClient() then
        table.insert(dec, workspace.CurrentCamera)
    end
    
    params.FilterDescendantsInstances = dec
    params.FilterType = Enum.RaycastFilterType.Exclude

    return workspace:Raycast(collider.CFrame.Position, Vector3.new(0, -raydis, 0), params)
end

return module