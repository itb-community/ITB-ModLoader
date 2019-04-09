-- Store reference to the C++ class so that we don't lose it
SkillEffectUserdata = SkillEffect

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

    -- Create our own SkillEffect constructor where we override functions
    -- We have to override them on each instance we create, since overriding them
    -- on the SkillEffect class updates all references to the function, even the ones
    -- we've saved ahead of time.
    function buildSkillEffect()
        local effect = SkillEffectUserdata()

        effect.AddGrapple = function(self, source, target, ...)
            local fx = SkillEffectUserdata()
            oldAddGrapple(fx, source, target, ...)
        
            local damageInstance = fx.effect:index(1)
            damageInstance.grappleData = {
                source = source,
                target = target
            }
        
            self.effect:push_back(damageInstance)
        end

        effect.AddProjectile = function(self, ...)
            oldAddProjectile(self, ...)
        end

        effect.AddArtillery = function(self, ...)
            oldAddArtillery(self, ...)
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
        self.q_effect:push_back(fx.effect:index(1))
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
