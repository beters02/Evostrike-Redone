local PhysicsService = game:GetService("PhysicsService")

local collisionGroups = {
    bullets = "Bullets",
    ragdolls = "Ragdolls",
    deadCharacters = "DeadCharacters",
    bulletHoles = "BulletHoles",
    bulletIgnore = "BulletIgnore",
    mollyDamageCast = "MollyDamageCast",
}
local cg = collisionGroups

local function registerCollisionGroups()
    for _, group in pairs(collisionGroups) do
        PhysicsService:RegisterCollisionGroup(group)
    end
end

local function setToIgnoreAllCollisionGroups(group: string)
    for _, rGroup in pairs(PhysicsService:GetRegisteredCollisionGroups()) do
        PhysicsService:CollisionGroupSetCollidable(group, rGroup.name, false)
    end
end

--[[ Init Functions ]]

local function initMain()
    PhysicsService:CollisionGroupSetCollidable(cg.bullets, cg.ragdolls, true)
    PhysicsService:CollisionGroupSetCollidable(cg.deadCharacters, cg.bullets, false)
    PhysicsService:CollisionGroupSetCollidable(cg.deadCharacters, cg.ragdolls, false)
    PhysicsService:CollisionGroupSetCollidable(cg.bulletHoles, "Players", false)
    PhysicsService:CollisionGroupSetCollidable(cg.bulletHoles, "PlayerFeet", false)
    PhysicsService:CollisionGroupSetCollidable(cg.bulletIgnore, cg.bullets, false)
    PhysicsService:CollisionGroupSetCollidable(cg.ragdolls, cg.ragdolls, true)
end

local function initMolly()
    setToIgnoreAllCollisionGroups(cg.mollyDamageCast)
    PhysicsService:CollisionGroupSetCollidable(cg.mollyDamageCast, "PlayerFeet", true)
end

--[[ Run ]]
registerCollisionGroups()
initMain()
initMolly()