-- //////////////////////////////////////////////////////////////////////////
-- Replacement of SkillEffect functions to allow detection of grapple,
-- artillery and projectiles.

function SpaceDamage:ListFields()
    return {
        "bEvacuate",
        "bHide",
        "bHideIcon",
        "bHidePath",
        "bKO_Effect",
        "bSimpleMark",
        "fDelay",
        "iAcid",
        "iCrack",
        "iDamage",
        "iFire",
        "iFrozen",
        "iInjure",
        "iPawnTeam",
        "iPush",
        "iShield",
        "iSmoke",
        "iTerrain",
        "loc",
        "sAnimation",
        "sImageMark",
        "sItem",
        "sPawn",
        "sScript",
        "sSound"
    }
end

function SpaceDamage:Clone()
    Assert.Equals("userdata", type(self), "Argument #0")

    local result = SpaceDamage()

    for _, k in ipairs(self:ListFields()) do
        result[k] = self[k]
    end

    return result
end

function SpaceDamage:ToTable()
    Assert.Equals("userdata", type(self), "Argument #0")

    local result = {}

    for _, k in ipairs(self:ListFields()) do
        result[k] = self[k]
    end

    return result
end

-- returns true if this space data contains metadata
-- it may contain other data as well, use IsMetadata to check if this is only metadata
function SpaceDamage:HasMetadata()
    Assert.Equals("userdata", type(self), "Argument #0")

    if not self.sScript then
        return false
    end
    
    return modApi:stringStartsWith(self.sScript, "return")
end

-- gets the metadata in the current space damage
function SpaceDamage:GetMetadata()
    Assert.Equals("userdata", type(self), "Argument #0")

    if not self:HasMetadata() then
        return {}
    end

    return loadstring(self.sScript)()
end

-- checks if this space damage is exclusively metadata
-- note, if you plan to use GetMetadata later, it is more efficient to use
-- local meta = spaceDamage:GetMetadata()
-- local isMetadata = not meta.storedInSourceDamage
function SpaceDamage:IsMetadata()
    Assert.Equals("userdata", type(self), "Argument #0")

    return self:HasMetadata() and not self:GetMetadata().storedInSourceDamage
end

function DamageList:AppendAll(list)
    Assert.Equals("userdata", type(self), "Argument #0")
    Assert.Equals("userdata", type(list), "Argument #1")

    for i = 1, list:size() do
        self:push_back(list:index(i))
    end
end

function DamageList:GetMetadata()
    local metadata = {}

    for i, v in ipairs(extract_table(self)) do
        if v:IsMetadata() then
            metadata[i] = loadstring(v.sScript)()
        else
            metadata[i] = false
        end
    end

    return metadata
end

function SkillEffect:GetMetadata()
    return self.effect:GetMetadata()
end
function SkillEffect:GetQueuedMetadata()
    return self.q_effect:GetMetadata()
end

function SkillEffect:AppendAll(other)
    Assert.Equals("userdata", type(self), "Argument #0")
    Assert.Equals("userdata", type(other), "Argument #1")

    self.effect:AppendAll(other.effect)
    self.q_effect:AppendAll(other.q_effect)
end

local function addDamageListMetadata(damageList, metadataTable, addToPrevious)
    -- store in the source damage if possible, prevents breaking the bombermechs AP cannon achievement
    local damageToModify
    if addToPrevious then
        damageToModify = damageList:back()
        if damageToModify.sScript ~= "" then
            LOGW("unable to save metadata from skill effect. Metadata \n" + save_table(metadataTable))
            return
        end
        metadataTable.storedInSourceDamage = true
    else
        damageToModify = SpaceDamage()
        metadataTable.storedInSourceDamage = false
    end
    damageToModify.sScript = "return " .. save_table(metadataTable)
    if not addToPrevious then
        damageList:push_back(damageToModify)
    end
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

    oldAddGrapple(self, source, target, anim, ...)
    -- store metadaata in the grapple space damage
    addDamageListMetadata(self.effect, metadataTable, true)
end

local function overrideProjectileOrArtillery(funcName, oldFunc)
    local damageList = modApi:stringStartsWith(funcName, "AddQueued") and "q_effect" or "effect"
    local metadataType = funcName:gsub("^Add", ""):gsub("^Queued", ""):lower()

    assert(metadataType == "projectile" or metadataType == "artillery", "This function only works for projectile or artillery weapons")

    SkillEffect[funcName] = function(self, source, damageInstance, projectileArt, delay)
        if not isUserdataPoint(source) then
            delay = projectileArt
            projectileArt = damageInstance
            damageInstance = source

            -- adding backwards compatibility for mods made before ITB 1.2
            -- it only works if piOrigin was set before AddProjectile/AddArtillery was called
            source = self.piOrigin ~= Point(-INT_MAX, -INT_MAX) and self.piOrigin or nil
        end

        if type(damageInstance) ~= 'userdata' then
            damageInstance = {}
        end

        local metadataTable = {}
        metadataTable.type = metadataType
        metadataTable.projectileArt = projectileArt
        metadataTable.source = source or (Pawn and Pawn:GetSpace()) or nil
        metadataTable.target = damageInstance.loc

        -- if the damage contains a script, add metadta first
        if damageInstance.sScript ~= "" then
            addDamageListMetadata(self[damageList], metadataTable, false)
        end

        -- call original function
        if source ~= nil then
            oldFunc(self, source, damageInstance, projectileArt, delay or PROJ_DELAY)
        elseif delay ~= nil then
            oldFunc(self, damageInstance, projectileArt, delay)
        else
            oldFunc(self, damageInstance, projectileArt)
        end

        -- if the damage does not contain a script, add metadata to the existing source
        if damageInstance.sScript == "" then
            addDamageListMetadata(self[damageList], metadataTable, true)
        end
    end
end

overrideProjectileOrArtillery("AddProjectile", fx.AddProjectile)
overrideProjectileOrArtillery("AddQueuedProjectile", fx.AddQueuedProjectile)
overrideProjectileOrArtillery("AddArtillery", fx.AddArtillery)
overrideProjectileOrArtillery("AddQueuedArtillery", fx.AddQueuedArtillery)

--[[
    Adds the specified damage instance to this damage list in such a way that
    only damages a pawn at the specified location, without causing any side
    effects to the board.
--]]
local damageableTerrain = {
    [TERRAIN_ICE] = true,
    [TERRAIN_MOUNTAIN] = true,
    [TERRAIN_SAND] = true,
    [TERRAIN_FOREST] = true
}
local function addSafeDamage(damageList, spaceDamage)
    -- Appropriated from Tarmean's Kinematics Squad

    spaceDamage = spaceDamage:Clone()
    local loc = spaceDamage.loc

    local terrain = Board:GetTerrain(loc)
    if terrain == TERRAIN_BUILDING then
        -- buildings don't reset health when re-setting iterrain 
        -- but they shouldn't overlap with units anyway
        return
    end

    local isDamaged = Board:IsDamaged(loc)
    if isDamaged then
        -- damaged ice/mountains are healed BEFORE we attack
        -- then our damage triggers and brings them back down to 1 health
        local dmg = SpaceDamage(loc)
        dmg.iTerrain = Board:GetTerrain(loc)

        damageList:push_back(dmg)
    elseif damageableTerrain[terrain] then
        local dmg = SpaceDamage(loc)
        dmg.iTerrain = TERRAIN_ROAD

        damageList:push_back(dmg)
    end

    if Board:IsFire(loc) and spaceDamage.iFire == EFFECT_REMOVE then
        -- Can't extinguish pawn without extinguishing the tile,
        -- the pawn will catch on fire again on the next game update step
        spaceDamage.iFire = 0
    end
    if not Board:IsSmoke(loc) then
        -- iTerrain doesn't remove the cloud
        spaceDamage.iSmoke = EFFECT_REMOVE
    end
    if (not isDamaged) and damageableTerrain[terrain] then
        -- this heals damageable terrain back up. This includes sand
        spaceDamage.iTerrain = terrain
    end
    damageList:push_back(spaceDamage)
    
    local dmg = SpaceDamage(loc)
    if
        not Board:IsFire(loc) and (
            (spaceDamage.iDamage ~= 0 and spaceDamage.iDamage ~= DAMAGE_ZERO and terrain == TERRAIN_FOREST) or
            spaceDamage.iFire == EFFECT_CREATE
        )
    then
        -- If a pawn stands on a forest we have to extinguish them as well
        dmg.sScript = string.format([[
            modApi:runLater(function()
                local loc = %s
                local emitter = Emitter_FireOut
                Emitter_FireOut = Emitter_Blank
                Board:SetFire(loc, false)
                Emitter_FireOut = emitter
            end)
        ]], loc:GetLuaString())
    end
    damageList:push_back(dmg)
end

SkillEffect.AddSafeDamage = function(self, spaceDamage)
    addSafeDamage(self.effect, spaceDamage)
end

SkillEffect.AddQueuedSafeDamage = function(self, spaceDamage)
    addSafeDamage(self.q_effect, spaceDamage)
end

SkillEffect.AddImpactSound = function(self, loc, sound)
	self:AddSound(sound)
	self.effect:back().loc = loc
end

SkillEffect.AddQueuedImpactSound = function(self, loc, sound)
	self:AddQueuedSound(sound)
	self.q_effect:back().loc = loc
end


-- //////////////////////////////////////////////////////////////////////////
-- Adds missing queued functions to SkillEffect, by Lemonymous

local function AddQueued(name)
    SkillEffect["AddQueued".. name] = function(self, ...)
        local fx = SkillEffect()
        fx["Add".. name](fx, ...)
        self.q_effect:AppendAll(fx.effect)
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
