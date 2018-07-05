local menuFontLarge = sdlext.font("fonts/JustinFont11Bold.ttf", 24)
-- This is not the correct font for tiny buttons. It seems like it's
-- Justin15, but non-bold?
local menuFontSmall = sdlext.font("fonts/Justin15.ttf", 15)

MainMenuButton = Class.inherit(Ui)

function MainMenuButton:new(style)
	Ui.new(self)

	style = style or "short"
	assert(type(style) == "string")

	-- difference in width between normal and highlighted states
	local wDiff = nil
	local font = nil

	if style == "long" then
		-- profile
		self:widthpx(412):heightpx(40)
		wDiff = 150
		font = menuFontLarge
	elseif style == "short" then
		-- continue, new game, etc.
		self:widthpx(345):heightpx(40)
		wDiff = 150
		font = menuFontLarge
	elseif style == "tiny" then
		-- achievements and statistics
		self:widthpx(300):heightpx(30)
		wDiff = 100
		font = menuFontSmall
	else
		error("Unknown MainMenuButton style: " .. style)
	end

	self:decorate({ DecoMainMenuButton(), DecoCaption(font) })

	self.onMouseEnter = function(button)
		if button.disabled then return end

		button.animations.unhighlight:stop()
		button.animations.highlight:start()

		local decoBtn = button.decorations[1]
		local p = decoBtn.bonusWidth / wDiff
		button.animations.highlight:setInitialPercent(p)
	end

	self.onMouseExit = function(button)
		if button.disabled then return end

		button.animations.highlight:stop()
		button.animations.unhighlight:start()

		local decoBtn = button.decorations[1]
		local p = (wDiff - decoBtn.bonusWidth) / wDiff
		button.animations.unhighlight:setInitialPercent(p)
	end

	self.animations.highlight = UiAnim(self, 150, function(anim, widget, percent)
		local decoBtn = widget.decorations[1]
		decoBtn.bonusWidth = math.min(wDiff, percent * wDiff)
		decoBtn.color = InterpolateColor(decoBtn.colorBase, decoBtn.colorHighlight, percent)
	end)

	self.animations.unhighlight = UiAnim(self, 150, function(anim, widget, percent)
		local decoBtn = widget.decorations[1]
		decoBtn.bonusWidth = math.max(0, wDiff - percent * wDiff)
		decoBtn.color = InterpolateColor(decoBtn.colorHighlight, decoBtn.colorBase, percent)
	end)

	self.animations.slideIn = UiAnim(self, 500, function(anim, widget, percent)
		local decoBtn = widget.decorations[1]
		local decoTxt = widget.decorations[2]

		-- That's not *quite* the right easing, but it's close enough.
		-- The game eases linearly up to ~80% of the animation, then
		-- sharply slows down.
		local blend = percent * (2 - percent)
		decoBtn.bonusX = math.min(0, widget.w * (blend - 1))
		
		decoTxt:setcolor(sdl.rgba(255, 255, 255, 255 * percent))
	end)

	self.animations.slideOut = UiAnim(self, 500, function(anim, widget, percent)
		local decoBtn = widget.decorations[1]
		local decoTxt = widget.decorations[2]

		local blend = percent * (2 - percent)
		decoBtn.bonusX = math.max(-widget.w, -widget.w * blend)

		decoTxt:setcolor(sdl.rgba(255, 255, 255, 255 * (1 - percent)))
	end)
end

