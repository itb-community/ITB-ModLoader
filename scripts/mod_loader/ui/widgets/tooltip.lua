UiTooltip = Class.inherit(UiWrappedText)

function UiTooltip:new()
	UiWrappedText.new(self, nil, deco.uifont.tooltipText.font, deco.uifont.tooltipText.set)
	
	self:padding(10)
		:decorate({ DecoFrame(deco.colors.buttoncolor, deco.colors.white, 3) })
	
	self.translucent = true
	self.limit = 28

	self.text = nil
	self.visible = false
end

function UiTooltip:draw(screen)
	local x = sdl.mouse.x()
	local y = sdl.mouse.y()
	if x + 20 + self.w <= screen:w() then
		self.x = x + 20
	else
		self.x = x - self.w
	end
	
	if y + self.h <= screen:h() then
		self.y = y
	else
		self.y = y - self.h
	end

	self.screenx = self.x
	self.screeny = self.y

	UiWrappedText.draw(self, screen)

	-- Update *after* our first call to draw()
	-- otherwise we get nasty flickering, since apparently
	-- the ui element is not being updated fast enough before
	-- it gets drawn?
	self:updateText()
end

function UiTooltip:updateText()
	if self.text ~= self.root.tooltip then
		self.w = 0
		self:setText(self.root.tooltip)
		self.w = self:maxChildSize() + self.padl + self.padr
		
		self:relayout()
	end

	self.visible = self.text and self.text ~= ""
end
