--[[
	Adds a function that allows replacing the repair skill icon for specific Pilot
	personalities.
--]]

local repairIcon = sdlext.surface("img/weapons/repair.png")

local iconHolder = nil
local repairReplacementIcons = {}

function RegisterRepairIconReplacement(personalityId, iconPath)
	assert(personalityId and type(personalityId) == "string")
	assert(iconPath == nil or type(iconPath) == "string")
	repairReplacementIcons[personalityId] = (iconPath and sdlext.surface(iconPath)) or nil
end

sdlext.addUiRootCreatedHook(function(screen, uiRoot)
	iconHolder = Ui()
		:widthpx(32):heightpx(80)
		:decorate({ DecoSurface() })
		:addTo(uiRoot)

	iconHolder.translucent = true
	iconHolder.visible = false

 	iconHolder.draw = function(self, screen)
 		self.visible = false
 		if Pawn and repairIcon:wasDrawn() then
			local srf = repairReplacementIcons[Pawn:GetPersonality()]
			if srf then
	 			self.x = repairIcon.x
	 			self.y = repairIcon.y
	 			self.visible = true
	 			self.decorations[1].surface = srf
			end
 		end

 		Ui.draw(self, screen)
 	end
end)

-- Example:
-- RegisterRepairIconReplacement("Original", "img/weapons/repair_mantis.png")
