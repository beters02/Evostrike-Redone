local Types = require(script.Parent.Parent:WaitForChild("Types"))
local SharedFunc = require(script.Parent.Parent:WaitForChild("Shared"))

local Deathmatch = {} :: Types.GamemodeClass

local Options = {} :: Types.GamemodeOptions
Options.BUY_MENU_ENABLED = true
Options.MAX_PLAYERS = 4
Options.MIN_PLAYERS = 2
Options.MAX_ROUNDS = 1
Options.ROUND_LENGTH = 60*5
Options.START_HEALTH = 100
Options.START_SHIELD = 0
Options.START_HELMET = false
Options.MAIN_MENU_TYPE = "Lobby"
Options.START_INVENTORY = {
    weapon  = {primary = "ak103", secondary = "glock17"},
    ability = {primary = "dash",  secondary = "longFlash"}
}
Deathmatch.Options = Options

--@summary Called before waitForPlayers
function Deathmatch:Start() end

function Deathmatch:End()
    
end

function Deathmatch:RoundStart()
    
end

function Deathmatch:RoundEnd(result)
    self:End()
end

function Deathmatch:PlayerJoinedWhileWaiting(player)
    
end

function Deathmatch:PlayerJoinedDuringGame(player)
    
end

function Deathmatch:PlayerLeftWhileWaiting(player)
    
end

function Deathmatch:PlayerLeftDuringGame(player)
    
end

function Deathmatch:SpawnPlayer(player)
    local char = player.Character or player.CharacterAdded:Wait()
    local spawnCf = self:GetPlayerSpawnPoint()
    char:WaitForChild("HumanoidRootPart").CFrame = spawnCf + Vector3.new(0, 2, 0)
end

function Deathmatch:PlayerDied(died, killer)
    
end

function Deathmatch:PlayerKilledSelf(player)
    
end

-- Player Functions

function Deathmatch:GetPlayerSpawnPoint()
    local points = {}
    local lowest
    local spawns

    spawns = self.Spawns.Zone1:GetChildren()

    for _, v in pairs(self.PlayerData:GetPlayers()) do
        if not v.Character or v.Character.Humanoid.Health <= 0 then continue end

        for _, spwn in pairs(spawns) do
            if spwn:IsA("Part") then
                if not points[spwn.Name] then points[spwn.Name] = 10000 end
                points[spwn.Name] -= (v.Character:WaitForChild("HumanoidRootPart").CFrame.Position - spwn.CFrame.Position).Magnitude

                if not lowest or points[spwn.Name] < lowest[2] then
                    lowest = {spwn, points[spwn.Name]}
                end
            end
        end
    end

    lowest = lowest and lowest[1] or spawns[math.random(1, #spawns)]
    return lowest.CFrame
end

return Deathmatch