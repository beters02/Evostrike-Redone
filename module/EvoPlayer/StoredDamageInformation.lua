-- Every time a player is spawned, we create a StoredDamageInformation class to store information about damage taken/received rather than using attributes.
-- Created on the Client and on the Server, handeled through EvoPlayer (Server), and PlayerScript (Client)
-- Clients can access StoredDamageInformation via EvoPlayer Bindable Events.

export type DamageInteraction = "Given" | "Received"

export type StorePacketInfo = {
    interactedPlayer: Player,
    interaction: DamageInteraction,
    damage: number
}

export type Packet = {
    damage: number,
    timeStamp: number,
    interactedPlayer: Player,
    interaction: DamageInteraction,
}

function clone(t)
    local n = {}
    for i, v in pairs(t) do
        if typeof(v) == "table" then
            n[i] = clone(v)
            continue
        end
        n[i] = v
    end
    return n
end

local StoredDamageInformation = {}
StoredDamageInformation.__index = StoredDamageInformation

function StoredDamageInformation.new(player)
    local self = setmetatable({}, StoredDamageInformation)
    self.Player = player
    self.Packets = {}
    return self
end

--@summary Manually store a Packet.
function StoredDamageInformation:Store(info: StorePacketInfo)
    local packet = {
        timeStamp = tick(),
        interaction = info.interaction,
        interactedPlayer = info.interactedPlayer,
        damage = info.damage
    } :: Packet
    self.Packets[#self.Packets+1] = packet
end

--@summary Store a Received Packet.
function StoredDamageInformation:PlayerReceivedDamage(damager, damage)
    self:Store({
        interaction = "Received",
        interactedPlayer = damager,
        damage = damage
    })
end

--@summary Store a Given Packet.
function StoredDamageInformation:PlayerGaveDamage(damaged, damage)
    self:Store({
        interaction = "Given",
        interactedPlayer = damaged,
        damage = damage
    })
end

--@summary Get all interactions.
function StoredDamageInformation:Get()
    return clone(self.Packets)
end

--@summary Get all interactions with a specific player.
function StoredDamageInformation:GetPlayerInteractions(player)
    local packets = {}
    for _, packet: Packet in pairs(self.Packets) do
        if packet.interactedPlayer == player then
            packets[#packets+1] = clone(packet)
        end
    end
    return packets
end

function StoredDamageInformation:Destroy()
    self = nil
end

return StoredDamageInformation