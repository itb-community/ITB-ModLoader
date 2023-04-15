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

function DamageList:AppendAll(list)
    Assert.Equals("userdata", type(self), "Argument #0")
    Assert.Equals("userdata", type(list), "Argument #1")

    for i = 1, list:size() do
        self:push_back(list:index(i))
    end
end

function SkillEffect:AppendAll(other)
    Assert.Equals("userdata", type(self), "Argument #0")
    Assert.Equals("userdata", type(other), "Argument #1")

    self.effect:AppendAll(other.effect)
    self.q_effect:AppendAll(other.q_effect)
end

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
