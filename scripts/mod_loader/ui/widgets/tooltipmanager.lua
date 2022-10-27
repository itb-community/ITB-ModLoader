
UiTooltipManager = Class.inherit(Ui)

function UiTooltipManager:new()
	Ui.new(self)

	self:width(1):height(1)
	self.ignoreMouse = true
	self.tooltipOffset = 10
	self.standardTooltip = UiTooltip()
end

function UiTooltipManager:relayout()
	if false
		or self.visible ~= true
		or self.parent.visible ~= true
	then
		return
	end

	if #self.children > 1 then
		Assert.Error("More than one custom tooltip attached")
	end

	local root = self.root
	local hoveredUi = root.hoveredchild

	if hoveredUi == nil then
		self.visible = false
		return
	end

	local tooltip_old = self.currentTooltip
	local tooltip = hoveredUi.customTooltip or self.standardTooltip

	if tooltip_old ~= tooltip then
		if tooltip_old then
			tooltip_old:detach()
		end

		self.currentTooltip = tooltip
		self:add(tooltip)
	end

	-- Give both the hovered widget
	-- and the tooltip an opportunity
	-- to redress the tooltip.
	if tooltip.onTooltipShown then
		tooltip:onTooltipShown(hoveredUi)
	end

	if hoveredUi.onTooltipShown then
		hoveredUi:onTooltipShown(tooltip)
	end

	-- Relayout once to give the tooltip
	-- a chance to resize before we align it.
	Ui.relayout(self)

	-- Let the tooltip update its position
	if tooltip.updatePosition then
		tooltip.updatePosition(self, tooltip, hoveredUi)
	else
		UiTooltip.updatePosition(self, tooltip, hoveredUi)
	end

	-- Fit tooltip within screen
	-- before relaying out again.
	tooltip.x = math.max(0, math.min(self.w - tooltip.w, tooltip.x))
	tooltip.y = math.max(0, math.min(self.h - tooltip.h, tooltip.y))
	tooltip.screenx = tooltip.x
	tooltip.screeny = tooltip.y

	Ui.relayout(self)
end
