local Lobby = {
    minimumPlayers = 1,
}

local Players = game:GetService("Players")
local Modules = game:GetService("ServerScriptService"):WaitForChild("Modules")
local Ability = require(Modules:WaitForChild("Ability"))
local Weapon = require(Modules:WaitForChild("Weapon"))

function Lobby:Start()
    local min = self.minimumPlayers or 1
    local players = Players:GetPlayers()
    if #players < min then
        repeat 
            task.wait()
            players = Players:GetPlayers()
        until #players >= min
    end

     -- add any players that have already joined
     for i, v in pairs(players) do
        task.spawn(function()
            self:SpawnPlayer(v)
        end)
    end

    -- init player added connection
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:SpawnPlayer(player)
    end)

    print("Gamemode " .. self.currentGamemode .. " started!")
end

function Lobby:SpawnPlayer(player)
    player:LoadCharacter()
    local character = player.Character or player.CharacterAdded:Wait()

    -- connect death events
    character.Humanoid.Died:Once(function()
        self:Died(player)
    end)

    -- teleport player to spawn
    local Spawns = workspace:FindFirstChild("Spawns")
    local spawnLoc = Spawns and Spawns:FindFirstChild("Default")
    spawnLoc = spawnLoc or workspace.SpawnLocation

    character.PrimaryPart.Anchored = true
    character:SetPrimaryPartCFrame(spawnLoc.CFrame + Vector3.new(0,2,0))
    character.PrimaryPart.Anchored = false

    -- give player knife
    Ability.Add(player, "Dash")
    Ability.Add(player, "LongFlash")
    Weapon.Add(player, "AK47")
    Weapon.Add(player, "Glock17")

end

function Lobby:Died(player)
    task.wait(2)
    self:SpawnPlayer(player)
end

return Lobby