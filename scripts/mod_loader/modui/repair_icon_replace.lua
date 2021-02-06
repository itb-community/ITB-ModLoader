--[[
	Adds a function that allows replacing the repair skill icon for specific Pilot
	personalities.
--]]

-- Technically this doesn't work for vanilla pilots who have custom repair abilities
-- (Mantis and Repairman), but we assume that no one will want to override those.
-- (Since you can do that by just replacing the image file)
local repairIcon = sdlext.getSurface({ path = "img/weapons/repair.png" })

local iconHolder = nil
local repairReplacementIcons = {}

function RegisterRepairIconReplacement(personalityId, iconPath)
	assert(personalityId and type(personalityId) == "string")
	assert(iconPath == nil or type(iconPath) == "string")
	repairReplacementIcons[personalityId] = (iconPath and sdlext.getSurface({ path = iconPath })) or nil
end

modApi.events.onUiRootCreated:subscribe(function(screen, uiRoot)
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
 		if Pawn and Pawn:IsSelected() and repairIcon:wasDrawn() then
			local srf = repairReplacementIcons[Pawn:GetPersonality()]

			if srf then
				-- Move the ui object to the place where the real repair icon is drawn
	 			self.x = repairIcon.x
	 			self.y = repairIcon.y

	 			-- Adjust clip rects to limit where the overlaid repair icon is drawn,
	 			-- so that we don't obscure the repair hotkey, or the pilot tooltip
	 			self.clipRect1.x = self.x
	 			self.clipRect1.y = self.y
	 			self.clipRect2.x = self.x
	 			self.clipRect2.y = self.y + self.clipRect1.h

	 			if rect_intersects(self.clipRect1, sdlext.CurrentWindowRect) then
	 				self.clipRect1.w = math.max(0, math.min(32, sdlext.CurrentWindowRect.x - self.x))
	 				self.clipRect2.w = math.max(0, math.min(18, sdlext.CurrentWindowRect.x - self.x))
	 			else
	 				self.clipRect1.w = 32
	 				self.clipRect2.w = 18
	 			end

	 			-- Set the ui object as visible, and update its decoration to the
	 			-- selected surface (repair icon)
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
