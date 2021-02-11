UiTooltip = Class.inherit(UiWrappedText)

function UiTooltip:new()
	UiWrappedText.new(self, nil, deco.uifont.tooltipText.font, deco.uifont.tooltipText.set)
	
	self:padding(10)
		:decorate({ DecoFrame(deco.colors.button, deco.colors.white, 3) })
	self.padt = self.padt - 1

	self.translucent = true
	self.limit = 28

	self.text = nil
	self.visible = false

	self.tooltipOffset = 10
end

--[[
	Compute aligned position for the specified axis (horizontal/vertical).

	Returns coordinate value positioning the 'self' argument aligned with the
	target widget's origin. If this would result in 'self' clipping outside of
	the screen bounds, this function instead returns coordinate value positioning
	'self' aligned with the target widget's end.
--]]
local function computeAlignedPos(self, widget, horizontal)
	if horizontal then
		return (widget.screenx + self.w <= ScreenSizeX())
			and widget.screenx
			or  (widget.screenx + widget.w - self.w)
	else
		return (widget.screeny + self.h <= ScreenSizeY())
			and widget.screeny
			or  (widget.screeny + widget.h - self.h)
	end
end

function UiTooltip:updateText()
	if self.text ~= self.root.tooltip then
		self.w = 0
		self:setText(self.root.tooltip)
		self.w = self:maxChildSize() + self.padl + self.padr
	end

	self.visible = self.text and self.text ~= ""
end

function UiTooltip:relayout()
	if modApi.floatyTooltips then
		-- Attach to the mouse cursor
		local x = sdl.mouse.x()
		local y = sdl.mouse.y()

		if x + 20 + self.w <= ScreenSizeX() then
			self.x = x + 20
		else
			self.x = x - self.w
		end

		if y + self.h <= ScreenSizeY() then
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

		if c.screenx + self.tooltipOffset + c.w + self.w <= ScreenSizeX() then
			x = c.screenx + self.tooltipOffset + c.w
			y = computeAlignedPos(self, c, false)
		elseif c.screenx - self.tooltipOffset - self.w >= 0 then
			x = c.screenx - self.tooltipOffset - self.w
			y = computeAlignedPos(self, c, false)
		else
			-- Can't fit the tooltip on either horizontal side
			-- of the widget, try vertical alignment
			x = computeAlignedPos(self, c, true)

			if c.screeny + self.tooltipOffset + c.h + self.h <= ScreenSizeY() then
				y = c.screeny + self.tooltipOffset + c.h
			elseif c.screeny - self.tooltipOffset - self.h >= 0 then
				y = c.screeny - self.tooltipOffset - self.h
			else
				-- Can't fit the tooltip anywhere outside of the widget.
				-- Give up, we'll just cover a part of it.
				y = computeAlignedPos(self, c, false)
			end
		end

		self.x = x
		self.y = y
		self.screenx = self.x
		self.screeny = self.y
	end

	self:updateText()
	UiWrappedText.relayout(self)
end
