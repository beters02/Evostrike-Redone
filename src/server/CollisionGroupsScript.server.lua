--[[
    Registering a new collision group will spawn a collision group with it automatically colliding with everything.
]]

local PhysicsService = game:GetService("PhysicsService")

local collisionGroups = { -- Name, CollideAll
    bullets = {"Bullets", true},
    ragdolls = {"Ragdolls", true},
    deadCharacters = {"DeadCharacters", true},
    bulletHoles = {"BulletHoles", true},
    bulletIgnore = {"BulletIgnore", true}, -- Bullet Ignore ClipBoxes
    bulletAndMovementIgnore = {"BulletAndMovementIgnore", true},
    mollyDamageCast = {"MollyDamageCast", false},
    playerDamageCast = {"PlayerDamageCast", false},
    flashCast = {"FlashCast", true},
    clipBoxes = {"ClipBoxes", true},
	movementIgnore = {"MovementIgnore", true},
	playerMovement = {"PlayerMovement", true},
    playerCollide = {"PlayerCollide", true},
	players = {"Players", false},
    playerFeet = {"PlayerFeet", false},
    bots = {"Bots", true},
    none = {"None", false},
    Weapons = {"Weapons", false},
    grenades = {"Grenades", true},
    ladders = {"Ladders", false},
    playerLadderCollider = {"PlayerLadderCollider", false}
}

-- this is so shit but convert collisionGroups tables back to table<string>
local cg = {}
for i, v in pairs(collisionGroups) do
    cg[i] = v[1]
end
--

function RegisterCollisionGroup(groupName: string, collideAll: boolean?) -- default: setToCollideAll = true
    if collideAll == nil then collideAll = true end
    PhysicsService:RegisterCollisionGroup(groupName)
    if not collideAll then
        util_setToCollideAll(groupName, collideAll)
    end
end


--
function util_setToCollideAll(group: string, bool: boolean)
    for _, rGroup in pairs(PhysicsService:GetRegisteredCollisionGroups()) do
        if collisionGroups[rGroup.name] and collisionGroups[rGroup.name][2] ~= bool then continue end -- Ignore if collision group is preset ignore/dont ignore all
        PhysicsService:CollisionGroupSetCollidable(group, rGroup.name, bool)
    end
end

--[[ Init Functions ]]

local function initCollisionGroups()

    local ignore = nil

    -- first we register all collision groups
    for _, group in pairs(collisionGroups) do
        RegisterCollisionGroup(group[1], true)

        -- if they want to set to ignore, register that here
        if not group[2] then
            if not ignore then ignore = {} end
            table.insert(ignore, group[1])
        end
    end

    -- ignore all collision if necessary
    if ignore then
        for _, group in pairs(ignore) do
            util_setToCollideAll(group, false)
        end
    end

end

local function initMain()

    -- bullets & bulletholes
    PhysicsService:CollisionGroupSetCollidable(cg.bullets, cg.ragdolls, true)
    PhysicsService:CollisionGroupSetCollidable(cg.bullets, cg.bulletIgnore, false)
    PhysicsService:CollisionGroupsAreCollidable(cg.playerDamageCast, "Players", true)
    PhysicsService:CollisionGroupsAreCollidable(cg.playerDamageCast, "PlayerFeet", true)
    PhysicsService:CollisionGroupsAreCollidable(cg.playerDamageCast, "Bots", true)

    PhysicsService:CollisionGroupSetCollidable("BulletAndMovementIgnore", "Players", false)
    PhysicsService:CollisionGroupSetCollidable("BulletAndMovementIgnore", "Bullets", false)
    PhysicsService:CollisionGroupSetCollidable("BulletAndMovementIgnore", "PlayerMovement", false)
    PhysicsService:CollisionGroupSetCollidable("BulletAndMovementIgnore", "PlayerFeet", false)

    -- abilities
    PhysicsService:CollisionGroupSetCollidable(cg.mollyDamageCast, "PlayerFeet", true)
    PhysicsService:CollisionGroupSetCollidable(cg.flashCast, "Weapons", false)

    -- map
    PhysicsService:CollisionGroupSetCollidable(cg.bulletIgnore, cg.bullets, false)
	
	-- player movement
	PhysicsService:CollisionGroupSetCollidable(cg.playerMovement, "Players", false)
	PhysicsService:CollisionGroupSetCollidable(cg.playerMovement, "PlayerFeet", false)
    PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("PlayerFeet", "PlayerFeet", false)
	PhysicsService:CollisionGroupSetCollidable("Players", "PlayerFeet", false)
	PhysicsService:CollisionGroupSetCollidable(cg.playerMovement, "MovementIgnore", false)
    PhysicsService:CollisionGroupSetCollidable(cg.playerMovement, "Default", false)
    PhysicsService:CollisionGroupSetCollidable(cg.playerMovement, "Bullets", false)
    PhysicsService:CollisionGroupSetCollidable(cg.playerMovement, "Bots", false)
    PhysicsService:CollisionGroupSetCollidable(cg.playerMovement, cg.playerMovement, false)
    PhysicsService:CollisionGroupSetCollidable("DeadCharacters", cg.playerMovement, false)
    PhysicsService:CollisionGroupSetCollidable("DeadCharacters", "Players", false)
    PhysicsService:CollisionGroupSetCollidable("DeadCharacters", "PlayerFeet", false)
    PhysicsService:CollisionGroupSetCollidable("DeadCharacters", "Default", true)
    PhysicsService:CollisionGroupSetCollidable("DeadCharacters", "ClipBoxes", true)
    PhysicsService:CollisionGroupSetCollidable("PlayerFeet", "Bots", false)
    PhysicsService:CollisionGroupSetCollidable("Players", "Bots", false)
    PhysicsService:CollisionGroupSetCollidable("Players", "Bullets", true)
    PhysicsService:CollisionGroupSetCollidable("Players", "Ladders", true)
    PhysicsService:CollisionGroupSetCollidable("PlayerMovement", "Ladders", true)
    PhysicsService:CollisionGroupSetCollidable("PlayerLadderCollider", "Ladders", true)
    PhysicsService:CollisionGroupSetCollidable("PlayerLadderCollider", "PlayerLadderCollider", false)

    -- flash cast
    PhysicsService:CollisionGroupSetCollidable(cg.flashCast, "Players", true)
    PhysicsService:CollisionGroupSetCollidable(cg.flashCast, "PlayerFeet", true)
    PhysicsService:CollisionGroupSetCollidable(cg.flashCast, "Bots", true)
    PhysicsService:CollisionGroupSetCollidable(cg.flashCast, cg.playerMovement, false)
    PhysicsService:CollisionGroupSetCollidable(cg.flashCast, cg.deadCharacters, false)
    PhysicsService:CollisionGroupSetCollidable(cg.flashCast, "BulletAndMovementIgnore", false)

    -- grenades
    PhysicsService:CollisionGroupSetCollidable("Grenades", cg.ragdolls, true)
    PhysicsService:CollisionGroupSetCollidable("Grenades", "Bullets", false)
    PhysicsService:CollisionGroupSetCollidable("Grenades", "Grenades", false)
    PhysicsService:CollisionGroupSetCollidable("Grenades", cg.bulletIgnore, false)
    PhysicsService:CollisionGroupSetCollidable("Grenades", cg.playerMovement, false)
    PhysicsService:CollisionGroupSetCollidable("Grenades", "Players", false)
    PhysicsService:CollisionGroupSetCollidable("Grenades", "PlayerFeet", false)
    PhysicsService:CollisionGroupSetCollidable("Grenades", "Weapons", false)

    -- weapons
    PhysicsService:CollisionGroupSetCollidable("Weapons", "Players", false)
    PhysicsService:CollisionGroupSetCollidable("Weapons", "PlayerFeet", false)
    PhysicsService:CollisionGroupSetCollidable("Weapons", cg.playerMovement, false)
    
end

local function initRagdolls()
    PhysicsService:CollisionGroupSetCollidable(cg.ragdolls, cg.ragdolls, true)
    PhysicsService:CollisionGroupSetCollidable(cg.ragdolls, "Default", true)
    PhysicsService:CollisionGroupSetCollidable(cg.ragdolls, "ClipBoxes", true)
    PhysicsService:CollisionGroupSetCollidable(cg.ragdolls, "BulletIgnore", true)
    PhysicsService:CollisionGroupSetCollidable(cg.ragdolls, "PlayerCollide", true)
    PhysicsService:CollisionGroupSetCollidable(cg.deadCharacters, cg.bullets, false)
	PhysicsService:CollisionGroupSetCollidable(cg.deadCharacters, cg.ragdolls, false)
	PhysicsService:CollisionGroupSetCollidable(cg.deadCharacters, "PlayerMovement", false)
    PhysicsService:CollisionGroupSetCollidable(cg.ragdolls, "PlayerMovement", false)
    PhysicsService:CollisionGroupSetCollidable(cg.ragdolls, "Players", false)
    PhysicsService:CollisionGroupSetCollidable(cg.ragdolls, "PlayerFeet", false)
end

--[[ Run ]]
initCollisionGroups()
initMain()
initRagdolls()