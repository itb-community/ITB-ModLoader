deco.surfaces.checkboxChecked = sdl.surface("resources/mods/ui/checkbox-checked.png")
deco.surfaces.checkboxUnchecked = sdl.surface("resources/mods/ui/checkbox-unchecked.png")
deco.surfaces.checkboxHoveredChecked = sdl.surface("resources/mods/ui/checkbox-hovered-checked.png")
deco.surfaces.checkboxHoveredUnchecked = sdl.surface("resources/mods/ui/checkbox-hovered-unchecked.png")


DecoCheckbox = Class.inherit(DecoSurface)
function DecoCheckbox:new()
	DecoSurface.new(self, deco.surfaces.checkboxUnchecked)
end

function DecoCheckbox:draw(screen, widget)
	if widget.checked ~= nil and widget.checked then
		if widget.hovered then
			self.surface = deco.surfaces.checkboxHoveredChecked
		else
			self.surface = deco.surfaces.checkboxChecked
		end
	else
		if widget.hovered then
			self.surface = deco.surfaces.checkboxHoveredUnchecked
		else
			self.surface = deco.surfaces.checkboxUnchecked
		end
	end
	
	DecoSurface.draw(self, screen, widget)
end
