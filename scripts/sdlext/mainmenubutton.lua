
DecoMainMenuButton = Class.inherit(UiDeco)
function DecoMainMenuButton:new()
	self.bg = sdl.rgba(0,0,0,153)
	self.bghl = sdl.rgba(0,0,0,190)
end

function DecoMainMenuButton:draw(screen,widget)
	local color = self.bg
	if widget.hovered then
		color = self.bghl
		widget.rect.w = widget.rect.w + 150
	end
	screen:drawrect(color, widget.rect)
	if widget.hovered then
		widget.rect.w = widget.rect.w - 150
	end
	
	widget.decorationx = widget.decorationx + 65
	widget.decorationy = widget.decorationy + 5
end
