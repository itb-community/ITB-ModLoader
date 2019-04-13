
-- //////////////////////////////////////////////////////////////////////////
-- Replacement of SkillEffect functions to allow detection of grapple,
-- artillery and projectiles.

-- Store reference to the C++ class so that we don't lose it
SkillEffectUserdata = SkillEffect

local function addDamageListMetadata(damageList, metadataTable)
    local metadataInstance = SpaceDamage()

    metadataInstance.sScript = "return " .. save_table(metadataTable)
    damageList:push_back(metadataInstance)
end

local function isMetadataDamageInstance(damageInstance)
    if not damageInstance.sScript then
        return false
    end
    
    return modApi:stringStartsWith(damageInstance.sScript, "return {")
end

local function getDamageListMetadata(damageList)
    local metadata = {}

    for i, v in ipairs(extract_table(damageList)) do
        if isMetadataDamageInstance(v) then
            metadata[i] = loadstring(v.sScript)()
        else
            metadata[i] = nil
        end
    end

    return metadata
end

function GetSkillMetadata(skill)
    return getDamageListMetadata(skill.effect)
end

function GetSkillQueuedMetadata(skill)
    return getDamageListMetadata(skill.q_effect)
end

-- Defer the override so that we don't mess with mods that index tables
-- in the global namespace (modApiExt)
function OverrideSkillEffect()
    if SkillEffectTable then
        SkillEffect = SkillEffectTable
        return
    end

    -- Create an initial SkillEffect instance that we use to grab
    -- references to the existing functions. We can't use the SkillEffect
    -- class directly, since it throws an error about missing static members.
    local fx = SkillEffect()
    local oldAddGrapple = fx.AddGrapple
    local oldAddArtillery = fx.AddArtillery
    local oldAddProjectile = fx.AddProjectile
    local oldAddQueuedArtillery = fx.AddQueuedArtillery
    local oldAddQueuedProjectile = fx.AddQueuedProjectile

    -- Create our own SkillEffect constructor where we override functions
    -- We have to override them on each instance we create, since overriding them
    -- on the SkillEffect class updates all references to the function, even the ones
    -- we've saved ahead of time.
    function buildSkillEffect()
        local effect = SkillEffectUserdata()

        effect.AddGrapple = function(self, source, target, anim, ...)
            local metadataTable = {}
            metadataTable.type = "grapple"
            metadataTable.source = Point(source.x, source.y)
            metadataTable.target = Point(source.x, source.y)
            metadataTable.anim = anim
            addDamageListMetadata(self.effect, metadataTable)

            oldAddGrapple(self, source, target, anim, ...)
        end

        effect.AddProjectile = function(self, damageInstance, projectileArt, delay, ...)
            if not delay and damageInstance.loc then
                delay = PROJ_DELAY
            end

            local metadataTable = {}
            metadataTable.type = "projectile"
            metadataTable.projectileArt = projectileArt
            metadataTable.source = Pawn and Pawn:GetSpace() or nil
            metadataTable.target = damageInstance.loc
            addDamageListMetadata(self.effect, metadataTable)

            oldAddProjectile(self, damageInstance, projectileArt, delay, ...)
        end

        effect.AddArtillery = function(self, damageInstance, projectileArt, delay, ...)
            if not delay and damageInstance.loc then
                delay = PROJ_DELAY
            end

            local metadataTable = {}
            metadataTable.type = "artillery"
            metadataTable.projectileArt = projectileArt
            metadataTable.source = Pawn and Pawn:GetSpace() or nil
            metadataTable.target = damageInstance.loc
            addDamageListMetadata(self.effect, metadataTable)

            oldAddArtillery(self, damageInstance, projectileArt, delay, ...)
        end

        effect.AddQueuedProjectile = function(self, damageInstance, projectileArt, delay, ...)
            if not delay and damageInstance.loc then
                delay = PROJ_DELAY
            end

            local metadataTable = {}
            metadataTable.type = "projectile"
            metadataTable.projectileArt = projectileArt
            metadataTable.source = Pawn and Pawn:GetSpace() or nil
            metadataTable.target = damageInstance.loc
            addDamageListMetadata(self.q_effect, metadataTable)

            oldAddQueuedProjectile(self, damageInstance, projectileArt, delay, ...)
        end

        effect.AddQueuedArtillery = function(self, damageInstance, projectileArt, delay, ...)
            if not delay and damageInstance.loc then
                delay = PROJ_DELAY
            end

            local metadataTable = {}
            metadataTable.type = "artillery"
            metadataTable.projectileArt = projectileArt
            metadataTable.source = Pawn and Pawn:GetSpace() or nil
            metadataTable.target = damageInstance.loc
            addDamageListMetadata(self.q_effect, metadataTable)

            oldAddQueuedArtillery(self, damageInstance, projectileArt, delay, ...)
        end

        return effect
    end

    -- Replace the SkillEffect global with our own version.
    -- Use metatable magic to make it completely transparent to existing code
    SkillEffect = {}
    setmetatable(SkillEffect, {
        __index = SkillEffectUserdata,
        __newindex = SkillEffectUserdata,
        __call = buildSkillEffect
    })

    SkillEffectTable = SkillEffect
end

function RestoreSkillEffect()
    SkillEffect = SkillEffectUserdata
end

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
