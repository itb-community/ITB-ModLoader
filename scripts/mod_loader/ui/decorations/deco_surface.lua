DecoSurface = Class.inherit(UiDeco)
function DecoSurface:new(surface)
	self.surface = surface
end

function DecoSurface:draw(screen, widget)
	if self.surface == nil then return end
	local r = widget.rect

	screen:blit(
		self.surface,
		nil,
		r.x + widget.decorationx,
		r.y + widget.decorationy + r.h / 2 - self.surface:h() / 2
	)
	
	widget.decorationx = widget.decorationx + self.surface:w()
end


DecoSurfaceOutlined = Class.inherit(DecoSurface)
function DecoSurfaceOutlined:new(surface, outlineWidth, bordercolor, hlcolor, scale)
	self.surfacenormal = sdl.scaled(
		scale or 2,
		sdl.outlined(
			surface,
			outlineWidth or 1,
			bordercolor or deco.colors.buttonborder
		)
	)
	self.surfacehl = sdl.scaled(
		scale or 2,
		sdl.outlined(
			surface,
			outlineWidth or 1,
			hlcolor or deco.colors.buttonborderhl
		)
	)
end

function DecoSurfaceOutlined:draw(screen, widget)
	if widget.hovered then
		self.surface = self.surfacehl
	else
		self.surface = self.surfacenormal
	end

	DecoSurface.draw(self, screen, widget)
end

DecoSurfaceAligned = Class.inherit(DecoSurface)
function DecoSurfaceAligned:new(surface, alignH, alignV)
	DecoSurface.new(self, surface)
	self.alignH = alignH
	self.alignV = alignV
end

function DecoSurfaceAligned:draw(screen, widget)
	if self.surface == nil then return end
	local r = widget.rect
	local x, y
	
	if self.alignH == nil or self.alignH == "left" then
		x = r.x + widget.decorationx
		widget.decorationx = widget.decorationx + self.surface:w()
	elseif self.alignH == "center" then
		x = math.floor(r.x + widget.decorationx + r.w / 2 - self.surface:w() / 2)
		widget.decorationx = widget.decorationx + self.surface:w()
	elseif self.alignH == "right" then
		x = r.x - widget.decorationx + r.w - self.surface:w()
		widget.decorationx = widget.decorationx - self.surface:w()
	end
	
	if self.alignV == nil or self.alignV == "top" then
		y = r.y + widget.decorationy
	elseif self.alignV == "center" then
		y = math.floor(r.y + widget.decorationy + r.h / 2 - self.surface:h() / 2)
	elseif self.alignV == "bottom" then
		y = r.y + widget.decorationy + r.h - self.surface:h()
	end
	
	screen:blit(self.surface, nil, x, y)
end
