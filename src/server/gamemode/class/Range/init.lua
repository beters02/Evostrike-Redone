local Range = {
    botsEnabled = true,
}

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)

function Range:SpawnPlayer(player)
    task.spawn(function()
        if not player:GetAttribute("Loaded") then
            repeat task.wait() until player:GetAttribute("Loaded")
        end
    
        player:LoadCharacter()
        task.wait()
        
        local hum = player.Character:WaitForChild("Humanoid")
        player.Character.Humanoid.Health = 100
    
        -- teleport player to spawn
        local spawnLoc = self.objects.spawns.Default
    
        player.Character.PrimaryPart.Anchored = true
        player.Character:SetPrimaryPartCFrame(spawnLoc.CFrame + Vector3.new(0,2,0))
        player.Character.PrimaryPart.Anchored = false
    
        Ability.Add(player, "Dash")
       --Ability.Add(player, "Satchel")
    
        Ability.Add(player, "Molly")
        --Ability.Add(player, "LongFlash")
        --Ability.Add(player, "HEGrenade")
    
        Weapon.Add(player, "AK47")
        Weapon.Add(player, "Glock17")
        Weapon.Add(player, "Knife", true)
    
        local conn
        conn = hum:GetPropertyChangedSignal("Health"):Connect(function()
            if self.status ~= "running" then conn:Disconnect() return end
            if hum.Health <= 0 then
                self:Died(player)
                conn:Disconnect()
            end
        end)
    end)
end

return Range