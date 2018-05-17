UiTooltip = Class.inherit(UiWrappedText)

function UiTooltip:new()
	UiWrappedText.new(self, nil, deco.uifont.tooltipText.font, deco.uifont.tooltipText.set)
	
	self:padding(10)
		:decorate({ DecoFrame(deco.colors.buttoncolor, deco.colors.white, 3) })
	self.padt = self.padt - 1

	self.translucent = true
	self.limit = 28

	self.text = nil
	self.visible = false
end

--[[
	Compute aligned position for the specified axis (horizontal/vertical).

	Returns coordinate value positioning the 'self' argument aligned with the
	target widget's origin. If this would result in 'self' clipping outside of
	the screen bounds, this function instead returns coordinate value positioning
	'self' aligned with the target widget's end.
--]]
local function computeAlignedPos(self, widget, screen, horizontal)
	if horizontal then
		return (widget.screenx + self.w <= screen:w())
			and widget.screenx
			or  (widget.screenx + widget.w - self.w)
	else
		return (widget.screeny + self.h <= screen:h())
			and widget.screeny
			or  (widget.screeny + widget.h - self.h)
	end
end

function UiTooltip:draw(screen)
	if modApi.floatyTooltips then
		-- Attach to the mouse cursor
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
	else
		-- Attach to the widget the user is currently hovering over, like
		-- ItB's own tooltips do

		-- shorthand due to laziness
		local c = self.root.hoveredchild

		if not c then return end

		local x = 0
		local y = 0

		if c.screenx + 10 + c.w + self.w <= screen:w() then
			x = c.screenx + 10 + c.w
			y = computeAlignedPos(self, c, screen, false)
		elseif c.screenx - 10 - self.w >= 0 then
			x = c.screenx - 10 - self.w
			y = computeAlignedPos(self, c, screen, false)
		else
			-- Can't fit the tooltip on either horizontal side
			-- of the widget, try vertical alignment
			x = computeAlignedPos(self, c, screen, true)

			if c.screeny + 10 + c.h + self.h <= screen:h() then
				y = c.screeny + 10 + c.h
			elseif c.screeny - 10 - self.h >= 0 then
				y = c.screeny - 10 - self.h
			else
				-- Can't fit the tooltip anywhere outside of the widget.
				-- Give up, we'll just cover a part of it.
				y = computeAlignedPos(self, c, screen, false)
			end
		end

		self.x = x
		self.y = y
		self.screenx = self.x
		self.screeny = self.y
	end

	UiWrappedText.draw(self, screen)

	-- Update *after* our first call to draw()
	-- otherwise we get nasty flickering, since apparently
	-- the ui element is not being updated fast enough before
	-- it gets drawn?
	self.laidOut = true
	self:updateText()
end

function UiTooltip:updateText()
	if self.text ~= self.root.tooltip then
		self.w = 0
		self:setText(self.root.tooltip)
		self.w = self:maxChildSize() + self.padl + self.padr

		self:relayout()
		self.laidOut = false
	end

	self.visible = self.laidOut and self.text and self.text ~= ""
end
