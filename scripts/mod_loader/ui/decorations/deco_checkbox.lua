deco.surfaces.checkboxChecked = sdl.surface("resources/mods/ui/checkbox-checked.png")
deco.surfaces.checkboxUnchecked = sdl.surface("resources/mods/ui/checkbox-unchecked.png")
deco.surfaces.checkboxHoveredChecked = sdl.surface("resources/mods/ui/checkbox-hovered-checked.png")
deco.surfaces.checkboxHoveredUnchecked = sdl.surface("resources/mods/ui/checkbox-hovered-unchecked.png")


DecoCheckbox = Class.inherit(DecoSurface)
function DecoCheckbox:new(checked, unchecked, hovChecked, hovUnchecked)
	self.srfChecked = checked or deco.surfaces.checkboxChecked
	self.srfUnchecked = unchecked or deco.surfaces.checkboxUnchecked
	self.srfHoveredChecked = hovChecked or deco.surfaces.checkboxHoveredChecked
	self.srfHoveredUnchecked = hovUnchecked or deco.surfaces.checkboxHoveredUnchecked

	DecoSurface.new(self, self.srfUnchecked)
end

function DecoCheckbox:draw(screen, widget)
	if widget.checked ~= nil and widget.checked then
		if widget.hovered then
			self.surface = self.srfHoveredChecked
		else
			self.surface = self.srfChecked
		end
	else
		if widget.hovered then
			self.surface = self.srfHoveredUnchecked
		else
			self.surface = self.srfUnchecked
		end
	end
	
	DecoSurface.draw(self, screen, widget)
end
