-- //////////////////////////////////////////////////////////////////////////
-- Replacement of SkillEffect functions to allow detection of grapple,
-- artillery and projectiles.

local function addDamageListMetadata(damageList, metadataTable)
    local metadataInstance = SpaceDamage()
    metadataInstance.sScript = "return " .. save_table(metadataTable)
    damageList:push_back(metadataInstance)
end

local function isMetadataDamageInstance(damageInstance)
    if not damageInstance.sScript then
        return false
    end
    
    return modApi:stringStartsWith(damageInstance.sScript, "return")
end

local function getDamageListMetadata(damageList)
    local metadata = {}

    for i, v in ipairs(extract_table(damageList)) do
        if isMetadataDamageInstance(v) then
            metadata[i] = loadstring(v.sScript)()
        else
            metadata[i] = false
        end
    end

    return metadata
end

SkillEffect.GetMetadata = function(self)
    return getDamageListMetadata(self.effect)
end
SkillEffect.GetQueuedMetadata = function(self)
    return getDamageListMetadata(self.q_effect)
end

-- Create an initial SkillEffect instance that we use to grab
-- references to the existing functions. We can't use the SkillEffect
-- class directly, since it throws an error about missing static members.
local fx = SkillEffect()

local oldAddGrapple = fx.AddGrapple
SkillEffect.AddGrapple = function(self, source, target, anim, ...)
    local metadataTable = {}
    metadataTable.type = "grapple"
    metadataTable.source = Point(source.x, source.y)
    metadataTable.target = Point(target.x, target.y)
    metadataTable.anim = anim
    addDamageListMetadata(self.effect, metadataTable)

    oldAddGrapple(self, source, target, anim, ...)
end

local function overrideProjectileOrArtillery(funcName, oldFunc)
    local damageList = modApi:stringStartsWith(funcName, "AddQueued") and "q_effect" or "effect"
    local metadataType = funcName:gsub("^Add", ""):gsub("^Queued", ""):lower()

    assert(metadataType == "projectile" or metadataType == "artillery", "This function only works for projectile or artillery weapons")

    SkillEffect[funcName] = function(self, damageInstance, projectileArt, delay, ...)
        if not delay and damageInstance.loc then
            delay = PROJ_DELAY
        end

        local metadataTable = {}
        metadataTable.type = metadataType
        metadataTable.projectileArt = projectileArt
        metadataTable.source = Pawn and Pawn:GetSpace() or nil
        metadataTable.target = damageInstance.loc
        addDamageListMetadata(self[damageList], metadataTable)
    
        oldFunc(self, damageInstance, projectileArt, delay, ...)
    end
end

overrideProjectileOrArtillery("AddProjectile", fx.AddProjectile)
overrideProjectileOrArtillery("AddQueuedProjectile", fx.AddQueuedProjectile)
overrideProjectileOrArtillery("AddArtillery", fx.AddArtillery)
overrideProjectileOrArtillery("AddQueuedArtillery", fx.AddQueuedArtillery)


-- //////////////////////////////////////////////////////////////////////////
-- Adds missing queued functions to SkillEffect, by Lemonymous

local function AddQueued(name)
    SkillEffect["AddQueued".. name] = function(self, ...)
        local fx = SkillEffect()
        fx["Add".. name](fx, ...)

        for _, v in ipairs(extract_table(fx.effect)) do
            self.q_effect:push_back(v)
        end
    end
end

AddQueued("AirStrike")
AddQueued("Animation")
AddQueued("BoardShake")
AddQueued("Bounce")
AddQueued("Delay")
AddQueued("Dropper")
AddQueued("Emitter")
AddQueued("Grapple")
AddQueued("Leap")
AddQueued("Sound")
