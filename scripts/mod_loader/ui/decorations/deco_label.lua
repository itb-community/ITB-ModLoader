DecoLabel = Class.inherit(DecoText)
function DecoLabel:new(text, options)
	options = options or {}

	font = options.font or deco.fonts.labelfont
	textset = options.textset or deco.textset(deco.colors.white, deco.colors.buttonhl, 2)

	self.fillcolor = options.fillcolor or deco.colors.buttonborder
	self.bordersize = options.bordersize or 2
	self.bordercolor = options.bordercolor or deco.colors.framebg
	self.alignRight = options.right or false
	self.alignBottom = options.bottom or false
	self.extraWidth = options.extraWidth or 0
	self.extraHeight = options.extraHeight or 0
	self.textOffsetX = options.textOffsetX or 0
	self.textOffsetY = options.textOffsetY or 0
	self.rect = sdl.rect(0,0,0,0)

	DecoText.new(self, text, font, textset)
end

function DecoLabel:draw(screen, widget)
	if widget.text then
		self:setsurface(widget.text)
	end

	local width = self.surface:w() + self.extraWidth
	local height = self.surface:h() + self.extraHeight
	local tri_size = math.min(width, height)

	local r = widget.rect

	-- draw main rect
	self.rect.w = width
	self.rect.h = height
	self.rect.x = self.alignRight and r.x + r.w - width or r.x
	self.rect.y = self.alignBottom and r.y + r.h - height or r.y

	screen:drawrect(self.fillcolor, self.rect)

	-- draw horizontal border
	self.rect.h = self.bordersize
	self.rect.y = self.alignBottom and self.rect.y - self.bordersize or self.rect.y + height

	screen:drawrect(self.bordercolor, self.rect)

	-- draw tri rect with diagonal border
	self.rect.w = tri_size + self.bordersize
	self.rect.h = tri_size + self.bordersize

	if self.alignRight then
		self.rect.x = r.x + r.w - width - self.rect.w
		if self.alignBottom then
			self.rect.y = r.y + r.h - height - self.bordersize
			drawtri_br(screen, self.bordercolor, self.rect)

			self.rect.x = self.rect.x + self.bordersize
			self.rect.y = self.rect.y + self.bordersize
			self.rect.w, self.rect.h = tri_size, tri_size
			drawtri_br(screen, self.fillcolor, self.rect)
		else
			self.rect.y = r.y
			drawtri_tr(screen, self.bordercolor, self.rect)

			self.rect.x = self.rect.x + self.bordersize
			self.rect.w, self.rect.h = tri_size, tri_size
			drawtri_tr(screen, self.fillcolor, self.rect)
		end
	else
		self.rect.x = r.x + width
		if self.alignBottom then
			self.rect.y = r.y + r.h - height - self.bordersize
			drawtri_bl(screen, self.bordercolor, self.rect)

			self.rect.y = self.rect.y + self.bordersize
			self.rect.w, self.rect.h = tri_size, tri_size
			drawtri_bl(screen, self.fillcolor, self.rect)
		else
			self.rect.y = r.y
			drawtri_tl(screen, self.bordercolor, self.rect)

			self.rect.w, self.rect.h = tri_size, tri_size
			drawtri_tl(screen, self.fillcolor, self.rect)
		end
	end

	-- draw text
	local x = self.alignRight and r.x + r.w - width or r.x
	local y = self.alignBottom and r.y + r.h - height or r.y

	screen:blit(
		self.surface,
		nil,
		x + self.textOffsetX,
		y + self.textOffsetY
	)
end
