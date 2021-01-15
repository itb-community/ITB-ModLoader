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

DecoDraw = Class.inherit(UiDeco)
function DecoDraw:new(drawFunction, color, rect, borderWidth)
	assert(type(drawFunction) == 'function')
	self.drawFunction = drawFunction
	self.color = color or deco.colors.buttonborder
	self.rect = sdl.rect(0,0,0,0)
	self.drawrect = rect
	self.borderWidth = borderWidth or 0
end

function DecoDraw:draw(screen, widget)
	local r = widget.rect
	
	if self.drawrect then
		self.rect.x = r.x + self.drawrect.x + widget.decorationx
		self.rect.y = r.y + self.drawrect.y + widget.decorationy
		self.rect.w = self.drawrect.w
		self.rect.h = self.drawrect.h
	else
		self.rect.x = r.x
		self.rect.y = r.y
		self.rect.w = r.w
		self.rect.h = r.h
	end
	
	self.drawFunction(screen, self.color, self.rect, self.borderWidth)
	
	widget.decorationx = widget.decorationx + self.rect.w + self.borderWidth
end
