--[[
	Allows paging through custom modded difficulty levels using the
	vanilla difficulty selection interface.
--]]

local arrLeft = nil
local arrRight = nil
local diffText = nil

local function changeDifficulty(newDiff)
	SetDifficulty(newDiff)

	arrLeft.disabled = newDiff <= 0
	arrRight.disabled = newDiff >= (#DifficultyLevels - 1)

	diffText.decorations[2]:setsurface(GetDifficultyFaceName(newDiff))
end

local function createUi(root)
	local pane = Ui()
		:width(1):height(1)
		:addTo(root)
	pane.translucent = true
	-- Hack. Having buttons return false in their mousemove causes
	-- UI's highlighting system to break, and fail to unhighlight
	-- the UI elements.
	-- Fix this by having their parent clean their mess.
	pane.mousemove = function(self, x, y)
		Ui.mousemove(self, x, y)

		if arrLeft.hovered and not arrLeft.containsMouse then
			arrLeft.hovered = false
		end
		if arrRight.hovered and not arrRight.containsMouse then
			arrRight.hovered = false
		end

		return false
	end

	local mask = Ui()
		:widthpx(156):heightpx(30)
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
			sdlext.surface("img/ui/hangar/small_arrow_left_on.png"),
			sdlext.surface("img/ui/hangar/small_arrow_left_select.png"),
			sdlext.surface("img/ui/hangar/small_arrow_left_off.png")
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
			sdlext.surface("img/ui/hangar/small_arrow_right_on.png"),
			sdlext.surface("img/ui/hangar/small_arrow_right_select.png"),
			sdlext.surface("img/ui/hangar/small_arrow_right_off.png")
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
			DecoCAlignedText(
				nil,
				sdlext.font("fonts/NunitoSans_Bold.ttf", 12),
				deco.textset(deco.colors.white, nil, nil, true)
			)
		})
		:addTo(pane)
	diffText.translucent = true

	local leaving = false

	pane.draw = function(self, screen)
		-- Only draw the difficulty UI while in the hangar
		self.visible = sdlext.isHangar()

		if self.visible then
			local origin = GetHangarOrigin()
			origin.x = origin.x + 640
			origin.y = origin.y + 30

			arrLeft:pospx (origin.x + 4          , origin.y + 4 )
			arrRight:pospx(origin.x + 28 + 90 + 4, origin.y + 4 )
			diffText:pospx(origin.x              , origin.y + 11)
			mask:pospx    (origin.x              , origin.y + 11 )

			local hideDifficultyUi = IsHangarWindowState() or
				(leaving and not mask.animations.fadeIn:isStarted())
			arrLeft.visible =  not hideDifficultyUi
			arrRight.visible = not hideDifficultyUi
			diffText.visible = not hideDifficultyUi
			mask.visible =     not hideDifficultyUi
		end

		Ui.draw(self, screen)
	end

	sdlext.addHangarEnteredHook(function(screen)
		-- Apply the difficulty we're starting with
		changeDifficulty(GetDifficulty())
	end)

	sdlext.addHangarLeavingHook(function(startGame)
		leaving = true

		if startGame then
			mask.animations.fadeIn:start()
		end
	end)

	sdlext.addHangarExitedHook(function(screen)
		leaving = false
		mask.animations.fadeIn:stop()
		mask.decorations[1].color = deco.colors.transparent
	end)
end

sdlext.addUiRootCreatedHook(function(screen, root)
	createUi(root)
end)
