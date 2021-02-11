deco.surfaces.checkboxChecked = sdlext.getSurface({ path = "resources/mods/ui/checkbox-checked.png" })
deco.surfaces.checkboxPartiallyChecked = sdlext.getSurface({ path = "resources/mods/ui/checkbox-partially-checked.png" })
deco.surfaces.checkboxUnchecked = sdlext.getSurface({ path = "resources/mods/ui/checkbox-unchecked.png" })
deco.surfaces.checkboxHoveredChecked = sdlext.getSurface({ path = "resources/mods/ui/checkbox-hovered-checked.png" })
deco.surfaces.checkboxHoveredPartiallyChecked = sdlext.getSurface({ path = "resources/mods/ui/checkbox-hovered-partially-checked.png" })
deco.surfaces.checkboxHoveredUnchecked = sdlext.getSurface({ path = "resources/mods/ui/checkbox-hovered-unchecked.png" })


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

DecoTriCheckbox = Class.inherit(DecoCheckbox)
function DecoTriCheckbox:new(checked, unchecked, hovChecked, hovUnchecked, partChecked, hovPartChecked)
	self.srfPartiallyChecked = partChecked or deco.surfaces.checkboxPartiallyChecked
	self.srfHoveredPartiallyChecked = hovPartChecked or deco.surfaces.checkboxHoveredPartiallyChecked

	DecoCheckbox.new(self, checked, unchecked, hovChecked, hovUnchecked)
end

function DecoTriCheckbox:draw(screen, widget)
	if widget.checked ~= nil and widget.checked then
		if widget.checked == true then
			if widget.hovered then
				self.surface = self.srfHoveredChecked
			else
				self.surface = self.srfChecked
			end
		else
			if widget.hovered then
				self.surface = self.srfHoveredPartiallyChecked
			else
				self.surface = self.srfPartiallyChecked
			end
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
