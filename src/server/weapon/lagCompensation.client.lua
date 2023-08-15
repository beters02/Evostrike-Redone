-- LAG COMPENSATION TEST
local LagCompensationEnabled = false
local WeaponGetServerFunc = nil
local Players = nil
local RunService = nil
WeaponGetServerFunc.OnInvoke = function(player, diff)
    if not LagCompensationEnabled then return false end
    local r = math.round(diff*100)
    local b = buffer + r
    if not store[b] then return false end
    return store[b].loc
end

local n = tick()
local tickRate = 1/32
local maxBuffer = 1024
store = {}
buffer = 1

local function pstrmatch(part, str)
    return string.match(part.Name, str)
end

local function getHitRegisteringPartsPositions(player)
    local ne = {}
    for i, v in pairs(player.Character:GetDescendants()) do
        if not v:IsA("BasePart") and not v:IsA("MeshPart") then continue end
        if pstrmatch(v, "Torso") or pstrmatch(v, "Head") or pstrmatch(v, "Arm") or pstrmatch(v, "Leg") or pstrmatch(v, "Foot") or pstrmatch(v, "Hand") then
            table.insert(ne, {[v.Name] = v.CFrame.Position})
        end
    end
    return ne
end

local function storeLocation(player)
    if not store[buffer] then
        store[buffer] = {tick(), loc = {}}
    end
    table.insert(store[buffer].loc, {player, getHitRegisteringPartsPositions(player)})
end

local function update()
    local t = tick()
    if t < n then return end
    n = tick() + tickRate

    if buffer >= maxBuffer then
        store[1] = nil
        table.remove(store, 1)
        buffer -= 1
    end

    for i, v in pairs(Players:GetPlayers()) do
        if not v.Character then continue end
        storeLocation(v)
    end
    buffer += 1
end

if LagCompensationEnabled then
    RunService.Heartbeat:Connect(update)
end