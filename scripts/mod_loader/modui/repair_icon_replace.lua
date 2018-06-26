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

	iconHolder.clipRect1 = sdl.rect(0, 0, 32, 65)
	iconHolder.clipRect2 = sdl.rect(0, 0, 18, 15)

 	iconHolder.draw = function(self, screen)
 		self.visible = false
 		if Pawn and repairIcon:wasDrawn() then
			local srf = repairReplacementIcons[Pawn:GetPersonality()]
			if srf then
	 			self.x = repairIcon.x
	 			self.y = repairIcon.y
	 			self.clipRect1.x = self.x
	 			self.clipRect1.y = self.y
	 			self.clipRect2.x = self.x
	 			self.clipRect2.y = self.y + self.clipRect1.h
	 			self.visible = true
	 			self.decorations[1].surface = srf
			end
 		end

 		screen:clip(self.clipRect1)
 		Ui.draw(self, screen)
 		screen:unclip()
 		screen:clip(self.clipRect2)
 		Ui.draw(self, screen)
 		screen:unclip()
 	end
end)

-- Example:
-- RegisterRepairIconReplacement("Original", "img/weapons/repair_mantis.png")
