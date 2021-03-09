--[[
	Allows paging through custom modded difficulty levels using the
	vanilla difficulty selection interface.
--]]

local arrLeft = nil
local arrRight = nil

local function changeDifficulty(newDiff)
	SetDifficulty(newDiff)

	arrLeft.disabled = newDiff <= 0
	arrRight.disabled = newDiff >= (#DifficultyLevels - 1)
end

local function createUi(root)

	local function arrowMousemove(self, x, y)
		Ui.mousemove(self, x, y)
		return false
	end

	local pane = Ui()
		:width(1):height(1)
		:setTranslucent(true)
		:addTo(root)

	arrLeft = Ui()
		:widthpx(28):heightpx(44)
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

	-- Need to override mousemove handler as well, since the
	-- game's buttons don't respond to clicks if they're not
	-- being hovered.
	arrLeft.mousemove = arrowMousemove
	arrRight.mousemove = arrowMousemove

	function pane:relayout()
		-- Only draw the difficulty UI while the hangar ui is visible
		self.visible = sdlext.isHangarUiVisible() and IsHangarWindowlessState()

		if self.visible then
			local origin = GetHangarOrigin()
			local rect = GetBackButtonRect()
			local diffArrowLeft = GetDifficultyRect()

			-- Hack. Having buttons return false in their mousemove causes
			-- UI's highlighting system to break, and fail to unhighlight
			-- the UI elements.
			-- Fix this by having their parent mark them as hovered.
			arrLeft.hovered = arrLeft.containsMouse
			arrRight.hovered = arrRight.containsMouse

			origin.x = origin.x + rect.x + rect.w
			origin.y = origin.y + 30
			arrLeft:pospx(origin.x + diffArrowLeft, origin.y + 4)
			arrRight:pospx(origin.x + diffArrowLeft + 130, origin.y + 4)

			-- The left/right arrows for changing difficulty gets enabled
			-- at some point after transitioning from the main menu to the
			-- hangar. Marking the exact time they get enabled is not easy.
			-- Rather than activating our custom arrow keys after a certain
			-- amount of time, we instead catch all clicks, and correct the
			-- displayed difficulty if a mismatch is detected.
			-- Relayout comes before the buttons gets redrawn, so it should
			-- be inperceptible for the user.
			local customDifficulty = GetDifficulty()
			local realDifficulty = GetRealDifficulty()
			if customDifficulty <= DIFF_HARD and realDifficulty ~= customDifficulty then
				changeDifficulty(realDifficulty)
			end
		end

		Ui.relayout(self)
	end

	modApi.events.onHangarUiShown:subscribe(function()
		arrLeft.visible = true
		arrRight.visible = true

		changeDifficulty(GetDifficulty())
	end)
	
	modApi.events.onHangarLeaving:subscribe(function()
		arrLeft.visible = false
		arrRight.visible = false
	end)

	modApi.events.onGameWindowResized:subscribe(function(screen)
		pane:width(1):height(1)
	end)
end

modApi.events.onUiRootCreated:subscribe(function(screen, root)
	createUi(root)
end)
