local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(Framework.shfc_tables.Location)
local DiedBind = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathBE")
local DiedEvent = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")

local hud = {}

function hud.initialize(player: Player)
    hud.player = player
    hud.gui = player.PlayerGui:WaitForChild("HUD")
    hud.infocv = hud.gui:WaitForChild("InfoCanvas")
    hud.infomainfr = hud.infocv:WaitForChild("MainFrame")
    hud.healthfr = hud.infomainfr:WaitForChild("HealthFrame")
    hud.weaponfr = hud.infomainfr:WaitForChild("WeaponFrame")
    hud.charfr = hud.infomainfr:WaitForChild("CharacterFrame")
    hud.killfr = hud.gui:WaitForChild("KillfeedFrame")

    hud.playerConnections = {}
    hud.killConnections = {}
    hud = hud.initKillfeeds(hud)

    hud.pccount = 0 -- total playerconn

    hud.health = require(script.Parent:WaitForChild("fc_health")).init(hud)
    hud.killfeed = require(script.Parent.fc_killfeed).init(hud)
    hud.yourkillfeed = require(script.Parent.fc_killfeed).init({killfr = hud.gui:WaitForChild("YourKillfeedFrame"), yours = true, upLength = 2})

    -- init var and resetvar
    local var = {lastSavedHealth = 0}
    hud.var = Tables.clone(var)
    hud._resetVar = function() hud.var = var end

    -- wait for children
    for _, v in pairs({hud.healthfr, hud.weaponfr}) do
        for i, ch in pairs(v:GetChildren()) do repeat task.wait() until ch end
    end

    return hud
end

function hud.initKillfeeds(self)

    -- connect your death
    self.killConnections._self = DiedBind.Event:Connect(function(killer)
        killer = killer or self.player
        self.killfeed:addItem(killer, self.player)
    end)

    -- connect other players diedevent to killfeed
    self.killConnections._other = DiedEvent.OnClientEvent:Connect(function(killed, killer)
        killer = killer or self.player
        self.killfeed:addItem(killer, killed)

        -- your kill feed
        if killer == self.player then
            self.yourkillfeed:addItem(killer, killed)
        end
    end)

    return self
end

--

function hud:ConnectPlayer()
    hud.pccount = 1

    -- update (health)
    local upc = hud.pccount
    table.insert(self.playerConnections, RunService.RenderStepped:Connect(function()
        if not self.player.Character then
            warn("Framework.cm_hud: There is no character for this player.. disconnecting this connection.")
            self.playerConnections[upc]:Disconnect()
            self.playerConnections[upc] = nil
            table.remove(self.playerConnections, upc)
            return
        end

        hud.health:update()
    end))

end

function hud:DisconnectPlayer()
    self._resetVar()

    for i, v in pairs(self.playerConnections) do
        v:Disconnect()
    end
    self.playerConnections = {}
end

return hud