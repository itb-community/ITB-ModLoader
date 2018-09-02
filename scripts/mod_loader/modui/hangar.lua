--[[
	Click handler for hangar buttons and hangar UI states.

	Everything here is held together with duct tape and hopeful wishes
	that the hangar UI will never change again.
	State machine golf, fun fun fun!
--]]

local hangarLeavingHooks = {}
function sdlext.addHangarLeavingHook(fn)
	assert(type(fn) == "function")
	table.insert(hangarLeavingHooks, fn)
end

local leaving = false
local function fireHangarLeavingHooks(startGame)
	leaving = true
	for i, hook in ipairs(hangarLeavingHooks) do
		hook(startGame)
	end
end

-- //////////////////////////////////////////////////////////////////////
-- State machine, constants

-- Technically we're working with hexadecimal constants,
-- not binary, but whatever.
local function hasbit(x, p)
	return x % (p + p) >= p
end

local UI_STATE_DEFAULT_NORMAL =    0x000001
local UI_STATE_DEFAULT_CUSTOM =    0x000010
local UI_STATE_DEFAULT =           0x000011
local UI_STATE_WINDOW_PILOT =      0x000100
local UI_STATE_WINDOW_SQUAD =      0x001000
local UI_STATE_WINDOW_SQUAD_EDIT = 0x010000
local UI_STATE_WINDOW_ACH =        0x100000
local UI_STATE_WINDOW =            0x111100

local uiState = UI_STATE_DEFAULT
local function isUiState(state)
	assert(type(state) == "number")
	return hasbit(uiState, state)
end

function IsHangarWindowState()
	return uiState == UI_STATE_WINDOW             or
	       hasbit(uiState, UI_STATE_WINDOW_ACH)   or
	       hasbit(uiState, UI_STATE_WINDOW_PILOT) or
	       hasbit(uiState, UI_STATE_WINDOW_SQUAD) or
	       hasbit(uiState, UI_STATE_WINDOW_SQUAD_EDIT)
end

function IsHangarWindowlessState()
	return uiState == UI_STATE_DEFAULT              or
	       hasbit(uiState, UI_STATE_DEFAULT_NORMAL) or
	       hasbit(uiState, UI_STATE_DEFAULT_CUSTOM)
end

function GetHangarOrigin()
	local origin = GetScreenCenter()

	-- Hangar UI is drawn at a different offset when
	-- window height is less than 1032px.
	-- This probably scales at certain thresholds when
	-- the UI can be scaled cleanly, but I can't test
	-- resolutions greater than 1920x1080, and it's
	-- difficult to extrapolate from one data point.
	if ScreenSizeY() < 1032 then
		origin.x = origin.x - 460
		origin.y = origin.y - 335
	else
		origin.x = origin.x - 385
		origin.y = origin.y - 285
	end

	return origin
end

-- //////////////////////////////////////////////////////////////////////
-- Window detection, state transitions

local squadBox =    Boxes.hangar_select
local achBox =      Boxes.hangar_ach_display
local pilotBox =    Rect2D(0, 0, squadBox.w - 150, squadBox.h)
local portraitBtn = Buttons.hangar_pilot.hitstats
local selectBtn =   Buttons.hangar_select.hitstats

local isSecretSquadUnlocked = false
local isSecretPilotsUnlocked = false

local function isWindowless(w, h)
	w = w or sdlext.CurrentWindowRect.w
	h = h or sdlext.CurrentWindowRect.h
	-- Check that there are no frames with shadow currently visible,
	-- other than the squad frame which is always drawn in the hangar.
	return  w == 420 and
	       (h == 480 or
	        -- taller when Custom Squad is selected
	        h == 493)
end

local function isCustomSquadUi(w, h)
	w = w or sdlext.CurrentWindowRect.w
	h = h or sdlext.CurrentWindowRect.h

	return w == 420 and h == 493
end

local function isSquadWindow(w, h)
	w = w or sdlext.CurrentWindowRect.w
	h = h or sdlext.CurrentWindowRect.h
	return (w == squadBox.w and h == squadBox.h) or
	        -- taller when Secret Squad is unlocked
	       (isSecretSquadUnlocked and
	        w == squadBox.w and h == 563)
end

local function isPilotWindow(w, h)
	w = w or sdlext.CurrentWindowRect.w
	h = h or sdlext.CurrentWindowRect.h
	return (w == pilotBox.w and h == pilotBox.h) or
	        -- wider when Secret Pilots are unlocked
	       (isSecretPilotsUnlocked and
	        w == squadBox.w and h == pilotBox.h)
end

local function isAchWindow(w, h)
	w = w or sdlext.CurrentWindowRect.w
	h = h or sdlext.CurrentWindowRect.h
	return w == achBox.w and h == achBox.h
end

local function isDismissClick(mx, my, button)
	if IsHangarWindowlessState() then
		return false
	end

	if isUiState(UI_STATE_WINDOW_PILOT) then
		if button ~= 1 then
			return false
		end

		if
			isPilotWindow() and
			not rect_contains(sdlext.CurrentWindowRect, mx, my)
		then
			return true
		end

		-- Hovering over pilot portraits shows tooltip with their info.
		-- In this case, we need to reference LastWindowRect here
		local r = isPilotWindow()
			and sdlext.CurrentWindowRect
			or  sdlext.LastWindowRect

		local gap = 25
		local startX = r.x + 35
		local startY = r.y + 43
		r = sdl.rect(startX, startY, 0, portraitBtn.h)

		-- Check the last pilot button
		r.w = 2 * portraitBtn.w + gap
		if Profile.pilot and rect_contains(r, mx, my) then
			return true
		end

		-- Check pilot portrait buttons
		r.w = portraitBtn.w
		local columns = isSecretPilotsUnlocked and 6 or 5
		for y = 0, 2 do
			r.x = startX

			for x = 0, columns - 1 do
				-- Skip the first two columns on the first row,
				-- since they're occupied by the Last Pilot button
				if y >= 1 or x >= 2 then
					if rect_contains(r, mx, my) then
						-- Check if the pilot is actually unlocked
						-- Secret pilots are not included in PilotList, so skip them
						if x < 5 then
							-- Compute index in the pilot list
							-- Decrement by 2 to account for Last Pilot button
							local idx = 1 + (y * 5 + x) - 2

							return list_contains(Profile.pilots, PilotList[idx])
						else
							return isSecretPilotsUnlocked
						end

						return false
					end
				end

				r.x = r.x + r.w + gap
			end

			r.y = r.y + r.h + gap
		end
	elseif isUiState(UI_STATE_WINDOW_SQUAD) then
		if button ~= 1 then
			return false
		end

		-- No need to check AchWindow, because when exiting it we
		-- move from AchWindow -> SquadWindow, so we stay in STATE_WINDOW
		if
			isSquadWindow() and
			not rect_contains(sdlext.CurrentWindowRect, mx, my)
		then
			local r = sdlext.CurrentWindowRect
			r = sdl.rect(r.x, r.y + r.h + 10, 450, 50)

			return not rect_contains(r, mx, my)
		end

		local inset = 25
		local gapH = 25
		local gapV = isSecretSquadUnlocked and 53 or 60

		local r2 = isSquadWindow()
			and sdlext.CurrentWindowRect
			or  sdlext.LastWindowRect

		local startX = r2.x + inset
		local startY = r2.y + inset

		local r = sdl.rect(startX, startY, selectBtn.w, selectBtn.h)

		for y = 0, 4 do
			r.x = startX

			for x = 0, 1 do
				local squadId = 1 + y * 2 + x

				if rect_contains(r, mx, my) then
					if Profile.squads[squadId] then
						return true
					else
						-- Squad is not unlocked yet, so this is not a dismiss click.
						modApi:scheduleHook(50, function()
							Profile = modApi:loadProfile()
						end)

						return false
					end
				end

				r.x = r.x + r.w + gapH
			end

			if isSecretSquadUnlocked then
				-- grumble grumble hardcoding offsets grumble
				gapV = y == 3
					and 46
					or  53
			end

			r.y = r.y + r.h + gapV
		end

		if isSecretSquadUnlocked then
			r.x = r2.x + (r2.w - r.w) / 2
			if rect_contains(r, mx, my) then
				return true
			end
		end
	elseif isUiState(UI_STATE_WINDOW_SQUAD_EDIT) then
		if button ~= 1 and button ~= 3 then
			return false
		end

		local center = Point(ScreenSizeX() / 2, ScreenSizeY() / 2)

		local r = sdl.rect(0, 0, 975, 531)
		r.x = center.x - r.w / 2
		r.y = center.y - r.h / 2 - 15

		return not rect_contains(r, mx, my)
	end

	return false
end

local squadBtn = Buttons.hangar_squad.hitstats
local function isSquadsButtonClick(mx, my)
	if IsHangarWindowlessState() then
		local r = sdl.rect(
			sdlext.CurrentWindowRect.x + 4,
			sdlext.CurrentWindowRect.y + sdlext.CurrentWindowRect.h - 44,
			squadBtn.w, squadBtn.h
		)
		return rect_contains(r, mx, my)
	end

	return false
end

local pilotsBtn = Buttons.hangar_pilots.hitstats
local function isPilotsButtonClick(mx, my)
	-- Pilot selection UI is not available for the secret squad
	if IsHangarWindowlessState() and Profile.last_squad ~= 10 then
		local r = sdl.rect(
			sdlext.CurrentWindowRect.x - 510 + 4,
			-- the pilot button is 1px lower than squad button
			-- goddamnit Matthew
			sdlext.CurrentWindowRect.y + sdlext.CurrentWindowRect.h - 43,
			pilotsBtn.w, pilotsBtn.h
		)
		return rect_contains(r, mx, my)
	end

	return false
end

local function isCustomSquadValid()
	return Profile.last_custom and #Profile.last_custom > 0
end

local recustomBtn = Buttons.hangar_recustom.hitstats
local function isEditSquadButtonClick(mx, my)
	if isUiState(UI_STATE_DEFAULT_CUSTOM) then
		if isCustomSquadValid() then
			-- Got valid custom squad selected, button is at the bottom
			local r = sdl.rect(
				sdlext.CurrentWindowRect.x + 4,
				sdlext.CurrentWindowRect.y + sdlext.CurrentWindowRect.h - 88,
				recustomBtn.w, recustomBtn.h
			)
			return rect_contains(r, mx, my)
		else
			-- No valid custom squad selected yet, button is in the center
			local r = sdl.rect(
				sdlext.CurrentWindowRect.x + 110,
				sdlext.CurrentWindowRect.y + 212,
				200, 75
			)
			return rect_contains(r, mx, my)
		end
	end

	return false
end

local function updateUiState()
	-- Some state transitions can be handled without
	-- having to explicitly code button detection.

	if isUiState(UI_STATE_WINDOW_SQUAD) then
		if isAchWindow() then
			uiState = UI_STATE_WINDOW_ACH
		end
	elseif isUiState(UI_STATE_WINDOW_ACH) then
		if isSquadWindow() then
			uiState = UI_STATE_WINDOW_SQUAD
		end
	elseif IsHangarWindowlessState() then
		-- default state can be narrowed down to
		-- specific state as soon as the player moves
		-- mouse cursor to neutral position
		uiState = isCustomSquadUi()
			and UI_STATE_DEFAULT_CUSTOM 
			or  UI_STATE_DEFAULT_NORMAL
	end
end

-- //////////////////////////////////////////////////////////////////////
-- translucent UI for click detection, tie it all together

local function createUi(root)
	local holder = Ui()
		:width(1):height(1)
		:addTo(root)
	holder.translucent = true
	holder.mousedown = function(self, x, y, button)
		-- Process events first so that children (btnBack and btnStart)
		-- process events BEFORE we change states.
		-- Prevents them from triggering when they shouldn't.
		local result = Ui.mousedown(self, x, y, button)

		if not leaving then
			if IsHangarWindowState() then
				-- Check if this is a dismiss click, so that we
				-- update the UI state var immediately instead
				-- of on next frame.
				if isDismissClick(x, y, button) then
					if
						isUiState(UI_STATE_WINDOW_SQUAD) or
						isUiState(UI_STATE_WINDOW_SQUAD_EDIT)
					then
						modApi:scheduleHook(50, function()
							Profile = modApi:loadProfile()
						end)
					end

					uiState = UI_STATE_DEFAULT
				end
			elseif
				IsHangarWindowlessState() and
				button == 1
			then
				if isPilotsButtonClick(x, y) then
					uiState = UI_STATE_WINDOW_PILOT
				elseif isSquadsButtonClick(x, y) then
					uiState = UI_STATE_WINDOW_SQUAD
				elseif isEditSquadButtonClick(x, y) then
					uiState = UI_STATE_WINDOW_SQUAD_EDIT
				end
			end
		end

		return result
	end

	local btnBack = Ui()
		:widthpx(120):heightpx(65)
		:addTo(holder)
	btnBack.translucent = true
	btnBack.mousedown = function(self, x, y, button)
		if
			not self.disabled         and
			self.primed               and
			not leaving               and
			button == 1               and
			IsHangarWindowlessState()
		then
			fireHangarLeavingHooks(false)
		end

		return Ui.mousedown(self, x, y, button)
	end

	local btnStart = Ui()
		:widthpx(120):heightpx(65)
		:addTo(holder)
	btnStart.translucent = true
	btnStart.mousedown = function(self, x, y, button)
		if
			not self.disabled         and
			self.primed               and
			button == 1               and
			not leaving               and
			IsHangarWindowlessState() and
			-- Start button is disabled when no valid custom squad is selected
			(Profile.last_squad ~= 9 or isCustomSquadValid())
		then
			fireHangarLeavingHooks(true)
		end

		return Ui.mousedown(self, x, y, button)
	end

	holder.draw = function(self, screen)
		local origin = GetHangarOrigin()
		btnBack:pospx(origin.x + 520, origin.y + 10)
		btnStart:pospx(origin.x + 800, origin.y + 10)

		self.visible = sdlext.isHangar()
		btnBack.primed  = self.visible and btnBack.containsMouse
		btnStart.primed = self.visible and btnStart.containsMouse

		if self.visible then
			updateUiState()
		end

		Ui.draw(self, screen)
	end

	sdlext.addPreKeyDownHook(function(keycode)
		if
			holder.visible             and
			not btnBack.disabled       and
			keycode == 27              and -- escape
			not sdlext.isConsoleOpen() and
			not leaving
		then
			if IsHangarWindowlessState() then
				fireHangarLeavingHooks(false)
			elseif
				isUiState(UI_STATE_WINDOW_SQUAD) or
				isUiState(UI_STATE_WINDOW_SQUAD_EDIT)
			then
				uiState = UI_STATE_DEFAULT
				modApi:scheduleHook(50, function()
					Profile = modApi:loadProfile()
				end)
			end
		end

		return false
	end)

	sdlext.addHangarEnteredHook(function(screen)
		Profile = modApi:loadProfile()
		isSecretSquadUnlocked = Profile.squads[11]
		isSecretPilotsUnlocked =
			list_contains(Profile.pilots, "Pilot_Mantis") or
			list_contains(Profile.pilots, "Pilot_Rock")   or
			list_contains(Profile.pilots, "Pilot_Zoltan")

		leaving = false
		uiState = UI_STATE_DEFAULT

		holder.visible = true
		holder:setfocus()

		btnBack.disabled = true
		btnStart.disabled = true
		modApi:scheduleHook(500, function()
			btnBack.disabled = false
			btnStart.disabled = false
		end)
	end)
end

sdlext.addUiRootCreatedHook(function(screen, root)
	createUi(root)
end)
