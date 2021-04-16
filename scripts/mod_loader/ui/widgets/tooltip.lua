UiTooltip = Class.inherit(UiBoxLayout)

function UiTooltip:new()
	UiBoxLayout.new(self)

	local title = UiWrappedText(nil, deco.uifont.tooltipTitleLarge.font, deco.uifont.tooltipTitleLarge.set)
		:addTo(self)
	title.limit = 28

	local text = UiWrappedText(nil, deco.uifont.tooltipText.font, deco.uifont.tooltipText.set)
		:addTo(self)
	text.limit = 28

	self
		:decorate({ DecoFrame(deco.colors.tooltipbg, deco.colors.white, 3) })
		-- set even combined padding (3+9=12)
		-- to avoid fraction when divided by 2
		:padding(9)
		:vgap(5)
	self.title = nil
	self.text = nil
	self.visible = false
	self.tooltipOffset = 10

	self.ui_title = title
	self.ui_text = text

	self.ignoreMouse = true
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
	if self.title ~= self.root.title or self.text ~= self.root.tooltip then
		self.w = 0
		self.ui_title:setText(self.root.tooltip_title)
		self.ui_text:setText(self.root.tooltip)
		self.w = math.max(self.ui_title:maxChildSize("width"), self.ui_text:maxChildSize("width")) + self.padl + self.padr
	end

	local isTitle = self.ui_title.text and self.ui_title.text ~= ""
	local isText = self.ui_text.text and self.ui_text.text ~= ""

	self.ui_title.visible = isTitle
	self.ui_text.visible = isText
	self.visible = isTitle or isText
end

function UiTooltip:relayout()
	-- build the tooltip with the whole screen available
	self.w = ScreenSizeX()
	self.h = ScreenSizeY()
	self:updateText()
	UiBoxLayout.relayout(self)

	-- adjust the position of the tooltip
	if modApi.floatyTooltips and not self.root.tooltip_static then
		-- Attach to the mouse cursor
		local x = sdl.mouse.x()
		local y = sdl.mouse.y()

		if x + self.tooltipOffset + self.w <= ScreenSizeX() then
			self.x = x + self.tooltipOffset
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

	-- relayout again to update children positions
	UiBoxLayout.relayout(self)
end
