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

	self.ui_title = title
	self.ui_text = text
end

function UiTooltip.updatePosition(tooltipManager, tooltip, hoveredUi)
	local staticTooltip = false
		or not modApi.floatyTooltips
		or tooltip.tooltip_static
		or hoveredUi.tooltip_static
		or hoveredUi.draggable and hoveredUi.dragged

	local offset = tooltip.tooltipOffset or tooltipManager.tooltipOffset
	local screen_w = tooltipManager.w
	local screen_h = tooltipManager.h
	local tooltip_w = tooltip.w
	local tooltip_h = tooltip.h
	local x = hoveredUi.x
	local y = hoveredUi.y
	local left = x - offset
	local top = y - offset
	local right = x + hoveredUi.w + offset
	local bot = y + hoveredUi.h + offset

	if staticTooltip then
		if right + tooltip_w <= screen_w then
			-- Draw tooltip to the right of the element
			x = right

		elseif left - tooltip_w >= 0 then
			-- Draw tooltip to the left of the element
			x = left - tooltip_w

		elseif bot + tooltip_h <= screen_h then
			-- Draw tooltip below the element
			y = bot
		else
			-- Draw tooltip above the element
			y = top - tooltip_h
		end
	else
		-- Attach the tooltip to the mouse cursor.
		x = sdl.mouse.x() + offset
		y = sdl.mouse.y()

		if x + tooltip_w > screen_w then
			x = x - tooltip_w - 2 * offset
		end
	end

	tooltip.x = x
	tooltip.y = y
end

function UiTooltip:onTooltipShown(hoveredUi)
	local title = hoveredUi.tooltip_title or ""
	local text = hoveredUi.tooltip or ""
	local isTitle = title ~= ""
	local isText = text ~= ""

	if self.ui_title.text ~= title or self.ui_text.text ~= text then
		self.w = 0

		if self.ui_title.text ~= title then
			self.ui_title:setText(title)
		end

		if self.ui_text.text ~= text then
			self.ui_text:setText(text)
		end

		self.w = math.max(self.ui_title:maxChildSize("width"), self.ui_text:maxChildSize("width")) + self.padl + self.padr
	end

	self.ui_title.visible = isTitle
	self.ui_text.visible = isText
	self.visible = isTitle or isText
end
