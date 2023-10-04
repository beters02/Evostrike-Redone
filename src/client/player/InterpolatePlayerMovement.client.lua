-- You cant predict the future! silly me
-- [[ DEPRECATED ]]
--[[

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

type OtherPlayer = {Player: Player, Character: Model?, Current: Vector3?, Target: Vector3?}
local OtherPlayers = {}
function OtherPlayers.new(player) return {Player = player, Character = false, Current = false, Target = false} end
function OtherPlayers.has(player) return OtherPlayers[player.Name] end
function OtherPlayers.haschar(player) local _has = OtherPlayers.has(player) return (_has and _has.Character) and _has or false end
function OtherPlayers.get(player)
    local _op = OtherPlayers[player.Name]
    if not _op then
        _op = OtherPlayers.new(player)
    end
    return _op
end

local function update(dt)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            interpolate(OtherPlayers.get(plr))
        else
            clearCharacterVar(plr)
        end
    end
end

--@summary Only ran if player has character
function interpolate(otherPlayer: OtherPlayer)
    if not otherPlayer.Character then
        otherPlayer.Character = otherPlayer.Player.Character
    end
end

function clearCharacterVar(player: Player)
    local _op = OtherPlayers.haschar(player)
    if _op then
        OtherPlayers[_op.Player.Name].Character = false
        OtherPlayers[_op.Player.Name].Current = false
        OtherPlayers[_op.Player.Name].Target = false
    end
end

RunService.RenderStepped:Connect(update)
Players.PlayerAdded:Connect(function(player) OtherPlayers[player.Name] = OtherPlayers.new(player) end)
Players.PlayerRemoving:Connect(function(player) OtherPlayers[player.Name] = nil end)]]