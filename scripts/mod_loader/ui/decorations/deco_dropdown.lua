deco.surfaces.dropdownOpen = sdlext.getSurface({ path = "resources/mods/ui/dropdown-arrow-opened.png" })
deco.surfaces.dropdownClosed = sdlext.getSurface({ path = "resources/mods/ui/dropdown-arrow-closed.png" })
deco.surfaces.dropdownOpenHovered = sdlext.getSurface({ path = "resources/mods/ui/dropdown-arrow-opened-hovered.png" })
deco.surfaces.dropdownClosedHovered = sdlext.getSurface({ path = "resources/mods/ui/dropdown-arrow-closed-hovered.png" })


DecoDropDown = Class.inherit(DecoSurface)
function DecoDropDown:new(open, closed, openHovered, closedHovered)
	self.open = open or deco.surfaces.dropdownOpen
	self.closed = closed or deco.surfaces.dropdownClosed
	self.openHover = openHovered or deco.surfaces.dropdownOpenHovered
	self.closedHover = closedHovered or deco.surfaces.dropdownClosedHovered

	DecoSurface.new(self, self.closed)
end

function DecoDropDown:draw(screen, widget)
	if widget.open ~= nil and widget.open then
		if widget.hovered then
			self.surface = self.openHover
		else
			self.surface = self.open
		end
	else
		if widget.hovered then
			self.surface = self.closedHover
		else
			self.surface = self.closed
		end
	end
	
	DecoSurface.draw(self, screen, widget)
end


DecoDropDownText = Class.inherit(DecoRAlignedText)
function DecoDropDownText:draw(screen, widget)
	if widget.strings[widget.choice] then
		self:setsurface(widget.strings[widget.choice])
	else
		self:setsurface(tostring(widget.value))
	end
	
	DecoRAlignedText.draw(self, screen, widget)
end
