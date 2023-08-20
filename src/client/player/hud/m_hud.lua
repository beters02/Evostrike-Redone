local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(Framework.shfc_tables.Location)

local hud = {}

function hud.initialize(player: Player)
    hud.player = player
    hud.gui = player.PlayerGui:WaitForChild("HUD")
    hud.infocv = hud.gui:WaitForChild("InfoCanvas")
    hud.infomainfr = hud.infocv:WaitForChild("MainFrame")
    hud.healthfr = hud.infomainfr:WaitForChild("HealthFrame")
    hud.weaponfr = hud.infomainfr:WaitForChild("WeaponFrame")
    hud.charfr = hud.infomainfr:WaitForChild("CharacterFrame")

    hud.playerConnections = {}
    hud.pccount = 0 -- total playerconn

    --hud.health = require(script.Parent:WaitForChild("fc_health")).init(hud)
    hud.health = require(script.Parent:WaitForChild("fc_health")).init(hud)

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

--

function hud:ConnectPlayer()
    hud.pccount = 1

    -- update
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