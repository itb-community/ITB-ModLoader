DecoSolid = Class.inherit(UiDeco)
function DecoSolid:new(color)
	self.color = color
end

function DecoSolid:draw(screen, widget)
	if self.color ~= nil and widget.rect ~= nil then
		screen:drawrect(self.color, widget.rect)
	end
end

DecoSolidHoverable = Class.inherit(DecoSolid)
function DecoSolidHoverable:new(color, hoverclr)
	DecoSolid.new(self,color)
	self.hoverclr = hoverclr
end

function DecoSolidHoverable:draw(screen, widget)
	if self.color ~= nil and self.hoverclr ~= nil and widget.rect ~= nil then
		if widget.hovered then
			screen:drawrect(self.hoverclr, widget.rect)
		else
			screen:drawrect(self.color, widget.rect)
		end
	end
end
