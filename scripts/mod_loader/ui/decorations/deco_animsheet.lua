--[[
	A decoration used to display non-animated pawn sprites on the game board.
--]]
DecoAnimSheet = Class.inherit(DecoSurface)
function DecoAnimSheet:new(pawnClass, scale, outlineColor, outlineWidth)
	self.clipRect = sdl.rect(0,0,0,0)
	self.scale = scale or 1
	self.outlineColor = outlineColor or deco.colors.transparent
	self.outlineWidth = outlineWidth or 1

	self:setAnim(pawnClass)
end

function DecoAnimSheet:setAnim(pawnClass)
	if not pawnClass then
		self.surface = nil
		return
	end

	local animData = ANIMS[pawnClass.Image]

	if not animData then
		self.surface = nil
		return
	end

	local surface = sdlext.surface("img/"..animData.Image)

	self.clipRect.w = surface:w()
	if getmetatable(animData) == ANIMS.MechUnit then
		self.clipRect.h = surface:h()
	else
		self.clipRect.h = surface:h() / animData.Height
	end
	self.yOffset = -self.clipRect.h * pawnClass.Tier

	self.surface = sdl.scaled(
		self.scale,
		sdl.outlined(
			surface,
			self.outlineWidth,
			self.outlineColor
		)
	)
end

function DecoAnimSheet:draw(screen, widget)
	if not self.surface then return end
	local r = widget.rect

	self.clipRect.x = r.x + widget.decorationx
	self.clipRect.y = r.y + widget.decorationy +
		r.h / 2 - self.clipRect.h / 2

	screen:clip(self.clipRect)

	screen:blit(
		self.surface,
		nil,
		self.clipRect.x,
		self.clipRect.y + self.yOffset
	)

	widget.decorationx = widget.decorationx + self.clipRect.w

	screen:unclip()
end
