
-- Adds missing queued functions to SkillEffect, by Lemonymous
local function AddQueued(name)
    SkillEffect["AddQueued".. name] = function(self, ...)
        fx = SkillEffect()
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
