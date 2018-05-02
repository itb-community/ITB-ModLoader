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
function DecoSurfaceOutlined:new(surface, levels, bordercolor, hlcolor, scale)
	self.surfacenormal = sdl.scaled(
		scale or 2,
		sdl.outlined(
			surface,
			levels or 1,
			bordercolor or deco.colors.buttonbordercolor
		)
	)
	self.surfacehl = sdl.scaled(
		scale or 2,
		sdl.outlined(
			surface,
			levels or 1,
			hlcolor or deco.colors.buttonborderhlcolor
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
