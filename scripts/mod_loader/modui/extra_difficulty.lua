--[[
	Allows paging through custom modded difficulty levels using the
	vanilla difficulty selection interface.
--]]

local arrLeft = nil
local arrRight = nil
local diffText = nil

--Closest match to the vanilla font; one pixel too wide.
local justinFont = nil
local diffTextset = deco.textset(deco.colors.white, nil, nil, false)


local function changeDifficulty(newDiff)
	SetDifficulty(newDiff)

	arrLeft.disabled = newDiff <= 0
	arrRight.disabled = newDiff >= (#DifficultyLevels - 1)

	diffText.decorations[2]:setsurface(GetDifficultyFaceName(newDiff):upper())
end

local function createUi(root)
	justinFont = sdlext.font("fonts/Justin15.ttf", 14)

	local pane = Ui()
		:width(1):height(1)
		:addTo(root)
	pane.translucent = true
	-- Hack. Having buttons return false in their mousemove causes
	-- UI's highlighting system to break, and fail to unhighlight
	-- the UI elements.
	-- Fix this by having their parent mark them as hovered.
	pane.mousemove = function(self, x, y)
		Ui.mousemove(self, x, y)

		arrLeft.hovered = arrLeft.containsMouse
		arrRight.hovered = arrRight.containsMouse

		return false
	end

	local mask = Ui()
		:widthpx(156):heightpx(35)
		:decorate({ DecoSolid(deco.colors.transparent) })
		:addTo(pane)
	mask.translucent = true

	local hangarBg = sdl.rgb(9, 7, 8)
	mask.animations.fadeIn = UiAnim(mask, 750, function(anim, widget, percent)
		widget.decorations[1].color = InterpolateColor(
			deco.colors.transparent,
			hangarBg,
			percent
		)
	end)

	arrLeft = Ui()
		:widthpx(28):heightpx(44)
		:decorate({ DecoSurfaceButton(
			sdlext.getSurface({ path = "img/ui/hangar/small_arrow_left_on.png" }),
			sdlext.getSurface({ path = "img/ui/hangar/small_arrow_left_select.png" }),
			sdlext.getSurface({ path = "img/ui/hangar/small_arrow_left_off.png" })
		) })
		:addTo(pane)

	-- Need to override mousedown handler, since onclicked()
	-- gets called on mouse UP, which is too late for the events
	-- to be passed through to the game, since it handles clicks
	-- on mouse down.
	-- We want to pass mouse clicks to the game to have it
	-- correctly page vanilla difficulty levels, since we can't
	-- set them through lua.
	arrLeft.mousedown = function(self, x, y, button)
		if
			not self.disabled                and
			Ui.mousedown(self, x, y, button) and
			button == 1
		then
			local prevDiff = GetDifficulty()
			changeDifficulty(prevDiff - 1)
			return not IsVanillaDifficultyLevel(prevDiff)
		end

		return false
	end
	-- Need to override mousemove handler as well, since the
	-- game's buttons don't respond to clicks if they're not
	-- being hovered.
	arrLeft.mousemove = function(self, x, y)
		Ui.mousemove(self, x, y)
		return false
	end

	arrRight = Ui()
		:widthpx(28):heightpx(44)
		:decorate({ DecoSurfaceButton(
			sdlext.getSurface({ path = "img/ui/hangar/small_arrow_right_on.png" }),
			sdlext.getSurface({ path = "img/ui/hangar/small_arrow_right_select.png" }),
			sdlext.getSurface({ path = "img/ui/hangar/small_arrow_right_off.png" })
		) })
		:addTo(pane)

	arrRight.mousedown = function(self, x, y, button)
		if
			not self.disabled                and
			Ui.mousedown(self, x, y, button) and
			button == 1
		then
			changeDifficulty(GetDifficulty() + 1)
			return not IsVanillaDifficultyLevel(GetDifficulty()) or
			       -- Special case: we were on a level below Easy.
			       -- Normally we want to increment level to the
			       -- next baseline, but in this case we don't have
			       -- a level to increment FROM, so prevent this
			       -- event from being passed through
			       GetDifficulty() == DIFF_EASY
		end

		return false
	end
	arrRight.mousemove = function(self, x, y)
		Ui.mousemove(self, x, y)
		return false
	end

	diffText = Ui()
		:widthpx(156):heightpx(30)
		:decorate({
			DecoSolid(deco.colors.framebg),
			DecoCAlignedText(nil, justinFont, diffTextset)
		})
		:addTo(pane)
	diffText.translucent = true

	local leaving = false

	pane.draw = function(self, screen)
		-- Only draw the difficulty UI while in the hangar
		self.visible = sdlext.isHangar()

		if self.visible then
			local origin = GetHangarOrigin()
			local rect = GetBackButtonRect()
			local diffArrowLeft = GetDifficultyRect()

			origin.x = origin.x + rect.x + rect.w
			origin.y = origin.y + 30
			arrLeft:pospx(origin.x + diffArrowLeft, origin.y + 4)
			arrRight:pospx(origin.x + diffArrowLeft + 130, origin.y + 4)
			diffText:pospx(origin.x + diffArrowLeft, origin.y + 13)
			mask:pospx(origin.x + diffArrowLeft, origin.y + 11)

			local hideDifficultyUi = IsHangarWindowState() or
				(leaving and not mask.animations.fadeIn:isStarted())
			arrLeft.visible =  not hideDifficultyUi
			arrRight.visible = not hideDifficultyUi
			diffText.visible = not hideDifficultyUi
			mask.visible =     not hideDifficultyUi
		end

		Ui.draw(self, screen)
	end

	modApi.events.onHangarEntered:subscribe(function(screen)
		-- Apply the difficulty we're starting with
		changeDifficulty(GetDifficulty())
	end)

	modApi.events.onHangarLeaving:subscribe(function(startGame)
		leaving = true

		if startGame then
			mask.animations.fadeIn:start()
		end
	end)

	modApi.events.onHangarExited:subscribe(function(screen)
		leaving = false
		mask.animations.fadeIn:stop()
		mask.decorations[1].color = deco.colors.transparent
	end)

	modApi.events.onGameWindowResized:subscribe(function(screen)
		pane:width(1):height(1)
	end)
end

modApi.events.onUiRootCreated:subscribe(function(screen, root)
	createUi(root)
end)
