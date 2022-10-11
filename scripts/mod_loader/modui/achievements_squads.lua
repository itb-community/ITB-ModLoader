
local NO_ICON = "img/achievements/No_Icon.png"
local TRANSFORMATION_MEDAL_2X = {
	{ scale = 2 },
	{ outline = { border = 2, color = deco.colors.buttonborder } }
}
local TRANSFORMATION_MEDAL_2X_HL = {
	{ scale = 2 },
	{ outline = { border = 2, color = deco.colors.achievementborder } }
}
local SURFACES = {
	COIN_SMALL = {
		ON = sdlext.getSurface{ path = "resources/mods/ui/coin_small_on.png" },
		OFF = sdlext.getSurface{ path = "resources/mods/ui/coin_small_off.png" }
	},
	COIN_LARGE = {
		ON = sdlext.getSurface{ path = "resources/mods/ui/coin_on.png" },
		OFF = sdlext.getSurface{ path = "resources/mods/ui/coin_off.png" },
	}
}

local SQUAD_INDICES = {
	-- page 1: shows random, custom, and 1-6
	{ -1, -1, 1, 2, 3, 4, 5, 6 },
	-- page 2: shows 7, 8, 12, 13, 14, 15, 16, and 11 (secret)
	{ 7, 8, 12, 13, 14, 15, 16, 11 }
}

modApi.events.onFtldatFinalized:subscribe(function()
	SURFACES.MEDALS_SMALL = {
		[2] = {
			NORMAL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_2.png" },
			HL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_2.png" }
		},
		[3] = {
			NORMAL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_3.png" },
			HL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_3.png" }
		},
		[4] = {
			NORMAL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_4.png" },
			HL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_4.png" }
		}
	}
	SURFACES.MEDALS_LARGE = {
		[2] = {
			NORMAL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_2.png", transformations = TRANSFORMATION_MEDAL_2X },
			HL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_2.png", transformations = TRANSFORMATION_MEDAL_2X_HL }
		},
		[3] = {
			NORMAL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_3.png", transformations = TRANSFORMATION_MEDAL_2X },
			HL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_3.png", transformations = TRANSFORMATION_MEDAL_2X_HL }
		},
		[4] = {
			NORMAL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_4.png", transformations = TRANSFORMATION_MEDAL_2X },
			HL = sdlext.getSurface{ path = "img/ui/hangar/ml_victory_4.png", transformations = TRANSFORMATION_MEDAL_2X_HL }
		}
	}
end)

local MEDAL_X_OFFSETS = {
	EASY = -27,
	NORMAL = -52,
	HARD = -77,
	UNFAIR = -101,
	NONE = -2
}

-- UI measurements
local UI = {
	MEDAL = {
		SMALL = {
			WIDTH = 19,
			HEIGHT = 28,
			WIDTH_HITBOX = 19,
			HEIGHT_HITBOX = 28,
		},
		LARGE = {
			WIDTH = 42,
			HEIGHT = 60,
			WIDTH_HITBOX = 42,
			HEIGHT_HITBOX = 60,
		}
	},
	COIN = {
		SMALL = {
			WIDTH = 20,
			HEIGHT = 20
		},
		LARGE = {
			WIDTH = 22,
			HEIGHT = 22,
			X_OFFSET = 44,
			Y_OFFSET = 44
		}
	},
	ACHIEVEMENT = {
		WIDTH = 64,
		HEIGHT = 64,
		WIDTH_HITBOX = 63,
		HEIGHT_HITBOX = 63,
	},
	HANGAR = {
		WIDTH = 416,
		HEIGHT = 113,
		X_OFFSET = 512,
		Y_OFFSET = 186,
		MEDAL = {
			X_OFFSET = -2,
			Y_OFFSET = -2
		},
		MEDAL_HOLDER = {
			WIDTH = 134,
			HEIGHT = 59,
			X_OFFSET = 30,
			Y_OFFSET = 29,
			HORIZONTAL_GAP = 3,
		},
		ACHIEVEMENT = {
			X_OFFSET = -1,
			Y_OFFSET = -1
		},
		ACHIEVEMENT_HOLDER = {
			WIDTH = 212,
			HEIGHT = 64,
			X_OFFSET = 185,
			Y_OFFSET = 24,
			HORIZONTAL_GAP = 11
		}
	},
	SQUAD_SELECT = {
		WIDTH = 635,
		HEIGHT = 303,
		HORIZONTAL_GAP = 315,
		VERTICAL_GAP = {
			SMALL_UI = 68,
			LARGE_UI = 69
		},
		X_OFFSET = 285,
		Y_OFFSET = {
			SMALL_UI = 91,
			LARGE_UI = 60
		},
		PROGRESS = {
			WIDTH = 160,
			HEIGHT = 32,
			MEDAL_HOLDER = {
				HORIZONTAL_GAP = 4,
				PADDING_LEFT = 7,
				PADDING_TOP = 2,
			},
			COIN_HOLDER = {
				HEIGHT = 20,
				HORIZONTAL_GAP = 5,
				PADDING_TOP = 8
			}
		}
	},
	ESCAPE_MENU = {
		WIDTH = 208,
		HEIGHT = 143,
		X_OFFSET = 361,
		Y_OFFSET = 60,
		MEDAL_HOLDER = {
			HEIGHT = 68,
			Y = 76,
			HORIZONTAL_GAP = 9,
			PADDING_LEFT = 27,
		},
		ACHIEVEMENT_HOLDER = {
			HEIGHT = 74,
			HORIZONTAL_GAP = 3,
			PADDING_ALL = 5
		},
		MOUSE_DETECTION_BOX = {
			HEIGHT = 25,
			Y = 95
		}
	}
}

-- Returns a deco draw function that consider the widget hovered
-- if the ancestor at depth 'hitboxDepth' contains the mouse.
local function buildDecoDrawFunction(drawFn, hitboxDepth)
	return function(self, screen, widget)
		local hitbox = widget

		for i = 1, hitboxDepth do
			hitbox = hitbox.parent or hitbox
		end

		local origWidgetHovered = widget.hovered
		widget.hovered = hitbox.containsMouse
		drawFn(self, screen, widget)
		widget.hovered = origWidgetHovered
	end
end

local function buildMedalUi(surface_bucket, squad_id, islandsSecured)
	local medalData = modApi.medals:readData(squad_id)
	local difficulty = medalData[islandsSecured.."islands"] or "NONE"
	local w, h, offset_x
	local decoSurface = DecoSurface()

	decoSurface.draw = buildDecoDrawFunction(DecoSurfaceOutlined.draw, 3)
	decoSurface.surfacenormal = SURFACES[surface_bucket][islandsSecured].NORMAL
	decoSurface.surfacehl = SURFACES[surface_bucket][islandsSecured].HL

	if surface_bucket == "MEDALS_LARGE" then
		offset_x = MEDAL_X_OFFSETS[difficulty] * 2
		w, h = UI.MEDAL.LARGE.WIDTH, UI.MEDAL.LARGE.HEIGHT
	else
		offset_x = MEDAL_X_OFFSETS[difficulty]
		w, h = UI.MEDAL.SMALL.WIDTH, UI.MEDAL.SMALL.HEIGHT
	end

	local medal = Ui()
		:widthpx(w)
		:heightpx(h)
		:decorate{ DecoAlign(offset_x, 0), decoSurface }
		:clip()
	medal.ignoreMouse = true

	return medal
end

local function buildMedal1xUi(squad_id, islandsSecured)
	return buildMedalUi("MEDALS_SMALL", squad_id, islandsSecured)
end

local function buildMedal2xUi(squad_id, islandsSecured)
	return buildMedalUi("MEDALS_LARGE", squad_id, islandsSecured)
end

local function clipped_draw(self, screen)
	if not self.visible then return end

	if modApi:isTipImage() then
		sdlext.occlude_draw(Ui, self, screen, sdlext.CurrentWindowRect)
	else
		Ui.draw(self, screen)
	end
end

local function buildCoinUi(surface_bucket, achievement)
	local surface = achievement:isComplete() and SURFACES[surface_bucket].ON or SURFACES[surface_bucket].OFF
	local w, h = UI.COIN.SMALL.WIDTH, UI.COIN.SMALL.HEIGHT

	if surface_bucket == "COIN_LARGE" then
		w, h = UI.COIN.LARGE.WIDTH, UI.COIN.LARGE.HEIGHT
	end

	local coin = Ui()
		:widthpx(w)
		:heightpx(h)
		:decorate{ DecoAlign(-5, 0), DecoSurface(surface) }
	coin.ignoreMouse = true
	coin.clipRect = sdl.rect(0,0,0,0)
	coin.draw = clipped_draw

	return coin
end

local function buildSmallCoinUi(achievement)
	return buildCoinUi("COIN_SMALL", achievement)
end

local function buildLargeCoinUi(achievement)
	return buildCoinUi("COIN_LARGE", achievement)
end

local function buildAchievementUi(achievement)
	local isComplete = achievement:isComplete()
	local isSecret = achievement.secret or false
	
	local solid = nil
	local surface = nil
	local decoBorder = DecoBorder(isComplete and deco.colors.achievementborder or deco.colors.buttonborder, 1, deco.colors.achievementborder, 4)
	decoBorder.draw = buildDecoDrawFunction(DecoBorder.draw, 1)
	
	if isSecret and not isComplete then
		surface = sdlext.getSurface{
			path = "resources/mods/ui/achv_secret.png"
		}
		solid = deco.colors.transparent
	else
		surface = sdlext.getSurface{
			path = achievement.image or NO_ICON,
			transformations = { { grayscale = not isComplete } }
		}
		solid = isComplete and deco.colors.transparent or deco.colors.halfblack
	end

	local ui = Ui()
		:widthpx(UI.ACHIEVEMENT.WIDTH)
		:heightpx(UI.ACHIEVEMENT.HEIGHT)
		:decorate({
			DecoSurface(surface, "center", "center"),
			DecoAnchor(),
			DecoSolid(solid),
			DecoAnchor(),
			decoBorder
		})
	ui.ignoreMouse = true
	ui.clipRect = sdl.rect(0,0,0,0)
	ui.draw = clipped_draw

	return ui
end

local function resetMedalTooltipText()
	modApi.modLoaderDictionary["Hangar_Island_Victory_2"] = nil
	modApi.modLoaderDictionary["Hangar_Island_Victory_3"] = nil
	modApi.modLoaderDictionary["Hangar_Island_Victory_4"] = nil
end

local function setMedalTooltipText(squad_id)
	local medalData = modApi.medals:readData(squad_id)
	for islandsSecured = 2, 4 do
		-- Uppercase first letter, followed by lowercase letters.
		local difficulty = medalData[islandsSecured.."islands"]:lower():gsub("^.", string.upper)
		local text_difficulty = GetText("Achievements_Medal_Island_Victory_".. difficulty)
		local text = GetText("Hangar_Island_Victory_"..islandsSecured):gsub("$1", text_difficulty)
		modApi.modLoaderDictionary["Hangar_Island_Victory_"..islandsSecured] = text
	end
end

local overriddenAchievementText = {}
local function resetAchievementTooltipText()
	for _, text in ipairs(overriddenAchievementText) do
		modApi.modLoaderDictionary[text] = nil
	end

	overriddenAchievementText = {}
end

local function setAchievementTooltipText(squad_id)
	resetAchievementTooltipText()

	local squadAchievements = modApi.achievements:getSquadAchievements(squad_id)
	local vanilla_squad_id = nil

	for squad_index, redirected_index in ipairs(modApi.squadIndices) do
		if squad_id == modApi.mod_squads[redirected_index].id then
			vanilla_squad_id = modApi.squadKeys[squad_index]
		end
	end

	Assert.NotEquals(nil, vanilla_squad_id)

	if squadAchievements ~= nil then
		for i, achievement in ipairs(squadAchievements) do
			if i > 3 then break end

			local base = string.format("Ach_%s_%s", vanilla_squad_id, i)
			local title = base.."_Title"
			local text = base.."_Text"
			local progress = base.."_Progress"
			local failed = base.."_Failed"

			modApi.modLoaderDictionary[title] = achievement.name
			modApi.modLoaderDictionary[text] = achievement:getTooltip()
			modApi.modLoaderDictionary[progress] = ""
			modApi.modLoaderDictionary[failed] = ""

			table.insert(overriddenAchievementText, title)
			table.insert(overriddenAchievementText, text)
			table.insert(overriddenAchievementText, progress)
			table.insert(overriddenAchievementText, failed)
		end
	end
end

-- Hangar Medal Ui
-- ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
local hangarMedalUi
local function destroyHangarMedalUi()
	if hangarMedalUi ~= nil then
		resetMedalTooltipText()
		resetAchievementTooltipText()
		hangarMedalUi:detach()
		hangarMedalUi = nil
	end
end

modApi.events.onHangarSquadSelected:subscribe(function(squad_id)
	destroyHangarMedalUi()

	hangarMedalUi = Ui()
	local medalHolder = Ui()
	local achievementHolder = UiBoxLayout()

	function hangarMedalUi:updatePosition()
		local hangarOrigin = GetHangarOrigin()
		self:setxpx(hangarOrigin.x + UI.HANGAR.X_OFFSET)
		self:setypx(hangarOrigin.y + UI.HANGAR.Y_OFFSET)
	end

	function hangarMedalUi:onGameWindowResized(screen, oldSize)
		self:updatePosition()
	end

	function hangarMedalUi:relayout()
		self.visible = sdlext.isHangar() and IsHangarWindowlessState()
		Ui.relayout(self)
	end

	sdlext.getUiRoot()
		:beginUi(hangarMedalUi)
			:setVar("translucent", true)
			:widthpx(UI.HANGAR.WIDTH)
			:heightpx(UI.HANGAR.HEIGHT)

			:beginUi(medalHolder)
				:setVar("translucent", true)
				:widthpx(UI.HANGAR.MEDAL_HOLDER.WIDTH)
				:heightpx(UI.HANGAR.MEDAL_HOLDER.HEIGHT)
				:setxpx(UI.HANGAR.MEDAL_HOLDER.X_OFFSET)
				:setypx(UI.HANGAR.MEDAL_HOLDER.Y_OFFSET)
			:endUi()

			:beginUi(achievementHolder)
				:setVar("translucent", true)
				:widthpx(UI.HANGAR.ACHIEVEMENT_HOLDER.WIDTH)
				:heightpx(UI.HANGAR.ACHIEVEMENT_HOLDER.HEIGHT)
				:setxpx(UI.HANGAR.ACHIEVEMENT_HOLDER.X_OFFSET)
				:setypx(UI.HANGAR.ACHIEVEMENT_HOLDER.Y_OFFSET)
				:hgap(UI.HANGAR.ACHIEVEMENT_HOLDER.HORIZONTAL_GAP)
				:dynamicResize(false)
			:endUi()
		:endUi()

	for islandsSecured = 2, 4 do
		if false
			or modApi:isModdedSquad(squad_id)
			or modApi.medals:isRibbonOvervalued(squad_id, islandsSecured)
		then
			local pos = islandsSecured - 2

			medalHolder
				:beginUi()
					:setVar("ignoreMouse", true)
					:widthpx(UI.MEDAL.LARGE.WIDTH_HITBOX)
					:heightpx(UI.MEDAL.LARGE.HEIGHT_HITBOX)
					:setxpx(pos * (UI.MEDAL.LARGE.WIDTH_HITBOX + UI.HANGAR.MEDAL_HOLDER.HORIZONTAL_GAP))

					:beginUi()
						:width(1):height(1)
						:setxpx(UI.HANGAR.MEDAL.X_OFFSET)
						:setypx(UI.HANGAR.MEDAL.Y_OFFSET)
						:decorate{ DecoSolid(deco.colors.framebg) }
						:add(buildMedal2xUi(squad_id, islandsSecured))
					:endUi()
				:endUi()
		end
	end

	if modApi:isModdedSquad(squad_id) then
		local squadAchievements = modApi.achievements:getSquadAchievements(squad_id)
		if squadAchievements ~= nil then
			for i, achievement in ipairs(squadAchievements) do
				if i > 3 then break end

				achievementHolder
					:beginUi()
						:setVar("translucent", true)
						:widthpx(UI.ACHIEVEMENT.WIDTH_HITBOX)
						:heightpx(UI.ACHIEVEMENT.HEIGHT_HITBOX)

						:beginUi(buildAchievementUi(achievement))
							:widthpx(UI.ACHIEVEMENT.WIDTH)
							:heightpx(UI.ACHIEVEMENT.HEIGHT)
							:setxpx(UI.HANGAR.ACHIEVEMENT.X_OFFSET)
							:setypx(UI.HANGAR.ACHIEVEMENT.Y_OFFSET)

							:beginUi(buildLargeCoinUi(achievement))
								:setxpx(UI.COIN.LARGE.X_OFFSET)
								:setypx(UI.COIN.LARGE.Y_OFFSET)
							:endUi()
						:endUi()
					:endUi()
			end
		end

		setMedalTooltipText(squad_id)
		setAchievementTooltipText(squad_id)
	end

	hangarMedalUi:updatePosition()
end)

modApi.events.onHangarSquadCleared:subscribe(function()
	destroyHangarMedalUi()
end)

modApi.events.onHangarLeaving:subscribe(function()
	destroyHangarMedalUi()
end)

-- Squad Selection Medal Ui
-- ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
local function detectConsoleCommand(keycode)
	if sdlext.isConsoleOpen() then
		if SDLKeycodes.isEnter(keycode) then
			modApi:scheduleHook(50, function()
				-- reload profile when pressing enter with the console open,
				-- in case a console commands was used to expand the mech hangar.
				Profile = modApi:loadProfile()
			end)
		end
	end
end

local squadSelectionMedalUi
local function destroySquadSelectionMedalUi()
	if squadSelectionMedalUi ~= nil then
		local unsubscribe_successful = modApi.events.onKeyPressed:unsubscribe(detectConsoleCommand)
		Assert.True(unsubscribe_successful, "Unsubscribe detectConsoleCommand")

		squadSelectionMedalUi:detach()
		squadSelectionMedalUi = nil
	end
end

local function draw_if_squad_unlocked(self, screen)
	self.visible = Profile.squads[self.squadIndex]

	if self.visible then
		if Boxes.hangar_select_big.x == sdlext.CurrentWindowRect.x and Boxes.hangar_select_big.y == sdlext.CurrentWindowRect.y - 25 then
			UiBoxLayout.draw(self, screen)
		else
			sdlext.occlude_draw(UiBoxLayout, self, screen, sdlext.CurrentWindowRect)
		end
	end
end

modApi.events.onSquadSelectionWindowShown:subscribe(function()
	destroySquadSelectionMedalUi()
	loadSquadSelection()

	local root = sdlext.getUiRoot()

	squadSelectionMedalUi = Ui()
		:width(1)
		:height(1)
		:addTo(root)
		:setTranslucent(true)

	function squadSelectionMedalUi:mousedown(mx, my, button)
		if button == 1 then
			modApi:scheduleHook(50, function()
				-- reload profile when pressing the left mouse button,
				-- in case a new squad has been unlocked.
				Profile = modApi:loadProfile()
			end)
		end

		return Ui.mousedown(self, mx, my, button)
	end

	for squadPage, indices in ipairs(SQUAD_INDICES) do
		local flow = UiFlowLayout()

		function flow:updatePosition()
			self:vgap(UI.SQUAD_SELECT.VERTICAL_GAP.SMALL_UI)
			self:setxpx(Boxes.hangar_select_big.x + UI.SQUAD_SELECT.X_OFFSET)
			self:setypx(Boxes.hangar_select_big.y + UI.SQUAD_SELECT.Y_OFFSET.SMALL_UI)
		end

		function flow:onGameWindowResized(screen, oldSize)
			self:updatePosition()
		end

		function flow:relayout()
			self.visible = true
				and sdlext.isAchievementsWindowVisible() ~= true
				and squadPage == sdlext.getSquadSelectionPage()
			UiFlowLayout.relayout(self)
		end

		squadSelectionMedalUi
			:beginUi(flow)
				:setVar("ignoreMouse", true)
				:widthpx(UI.SQUAD_SELECT.WIDTH)
				:heightpx(UI.SQUAD_SELECT.HEIGHT)
				:hgap(UI.SQUAD_SELECT.HORIZONTAL_GAP)
				:dynamicResize(false)
			:endUi()

		for visualIndex, squadIndex in ipairs(indices) do
			-- always added to ensure modded squads show in the right spot when vanilla squads exist
			local squadProgressUi = Ui()
				:widthpx(UI.SQUAD_SELECT.PROGRESS.WIDTH)
				:heightpx(UI.SQUAD_SELECT.PROGRESS.HEIGHT)
				:addTo(flow)

			-- -1 means random or custom
			if squadIndex ~= -1 then
				-- mod loader squad index is 2 less than the true index for secret squad and above
				local modSquadIndex = squadIndex > 10 and squadIndex - 2 or squadIndex
				local trueSquadIndex = modApi.squadIndices[modSquadIndex]
				local squad_id = modApi.mod_squads[trueSquadIndex].id

				local medalHolder = Ui()
				medalHolder.squadIndex = squadIndex
				medalHolder.padt = UI.SQUAD_SELECT.PROGRESS.MEDAL_HOLDER.PADDING_TOP
				medalHolder.padl = UI.SQUAD_SELECT.PROGRESS.MEDAL_HOLDER.PADDING_LEFT
				medalHolder.draw = draw_if_squad_unlocked

				local coinHolder = UiBoxLayout()
				coinHolder.squadIndex = squadIndex
				coinHolder.padt = UI.SQUAD_SELECT.PROGRESS.COIN_HOLDER.PADDING_TOP
				coinHolder.draw = draw_if_squad_unlocked

				squadProgressUi
					:beginUi(medalHolder)
						:width(0.5)
						:height(1)
					:endUi()
					:beginUi(coinHolder)
						:width(0.5)
						:heightpx(UI.SQUAD_SELECT.PROGRESS.COIN_HOLDER.HEIGHT)
						:pos(0.5, 0)
						:hgap(UI.SQUAD_SELECT.PROGRESS.COIN_HOLDER.HORIZONTAL_GAP)
						:dynamicResize(false)
					:endUi()

				for islandsSecured = 2, 4 do
					if false
						or modApi:isModdedSquad(squad_id)
						or modApi.medals:isRibbonOvervalued(squad_id, islandsSecured)
					then
						local pos = islandsSecured - 2

						medalHolder
							:beginUi()
								:widthpx(UI.MEDAL.SMALL.WIDTH)
								:heightpx(UI.MEDAL.SMALL.HEIGHT)
								:setxpx(pos * (UI.MEDAL.SMALL.WIDTH_HITBOX + UI.SQUAD_SELECT.PROGRESS.MEDAL_HOLDER.HORIZONTAL_GAP))
								-- Draw medal background and recreate two
								-- lines covered by the solid background.
								:decorate{
									DecoSolid(deco.colors.framebg),
									DecoDraw(
										screen.drawrect,
										deco.colors.buttonborder,
										sdl.rect(0,7,UI.MEDAL.SMALL.WIDTH,2)
									),
									DecoAnchor(),
									DecoDraw(
										screen.drawrect,
										deco.colors.buttonborder,
										sdl.rect(0,16,UI.MEDAL.SMALL.WIDTH,2)
									),
								}
								:add(buildMedal1xUi(squad_id, islandsSecured))
							:endUi()
					end
				end

				if modApi:isModdedSquad(squad_id) then
					local squadAchievements = modApi.achievements:getSquadAchievements(squad_id)

					if squadAchievements ~= nil then
						for i, achievement in ipairs(squadAchievements) do
							if i > 3 then break end

							buildSmallCoinUi(achievement)
								:addTo(coinHolder)
						end
					end
				end
			end
		end

		flow:updatePosition()
	end

	modApi.events.onKeyPressed:subscribe(detectConsoleCommand)
end)

modApi.events.onSquadSelectionWindowHidden:subscribe(function()
	destroySquadSelectionMedalUi()
end)

-- Escape Menu Medal Ui
-- ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
local escapeMenuMedalUi
local function destroyEscapeMenuMedalUi()
	if escapeMenuMedalUi ~= nil then
		resetMedalTooltipText()
		resetAchievementTooltipText()
		escapeMenuMedalUi:detach()
		escapeMenuMedalUi = nil
	end
end

modApi.events.onEscapeMenuWindowShown:subscribe(function()
	destroyEscapeMenuMedalUi()
	loadSquadSelection()

	local squad_id = GAME.additionalSquadData.squad
	if not modApi:isModdedSquad(squad_id) then
		return
	end

	local root = sdlext.getUiRoot()
	escapeMenuMedalUi = Ui()
		:widthpx(UI.ESCAPE_MENU.WIDTH)
		:heightpx(UI.ESCAPE_MENU.HEIGHT)
		:addTo(root)

	function escapeMenuMedalUi:relayout()
		self:pospx(Boxes.escape_box.x + UI.ESCAPE_MENU.X_OFFSET, Boxes.escape_box.y + UI.ESCAPE_MENU.Y_OFFSET)
		self.visible = not sdlext.isAchievementsWindowVisible()    and
		               not sdlext.isAbandonTimelineWindowVisible()
		Ui.relayout(self)
	end

	escapeMenuMedalUi.translucent = true
	escapeMenuMedalUi:relayout()

	local achievementHolder = UiBoxLayout()
		:width(1)
		:heightpx(UI.ESCAPE_MENU.ACHIEVEMENT_HOLDER.HEIGHT)
		:hgap(UI.ESCAPE_MENU.ACHIEVEMENT_HOLDER.HORIZONTAL_GAP)
		:padding(UI.ESCAPE_MENU.ACHIEVEMENT_HOLDER.PADDING_ALL)
		:dynamicResize(false)
		:addTo(escapeMenuMedalUi)
	achievementHolder.translucent = true

	local medalHolder = UiBoxLayout()
		:width(1)
		:heightpx(UI.ESCAPE_MENU.MEDAL_HOLDER.HEIGHT)
		:setypx(UI.ESCAPE_MENU.MEDAL_HOLDER.Y)
		:hgap(UI.ESCAPE_MENU.MEDAL_HOLDER.HORIZONTAL_GAP)
		:dynamicResize(false)
		:addTo(escapeMenuMedalUi)
	medalHolder.padl = UI.ESCAPE_MENU.MEDAL_HOLDER.PADDING_LEFT
	medalHolder.ignoreMouse = true

	local mouseDetectionBox = Ui()
		:width(1)
		:heightpx(UI.ESCAPE_MENU.MOUSE_DETECTION_BOX.HEIGHT)
		:setypx(UI.ESCAPE_MENU.MOUSE_DETECTION_BOX.Y)
		:addTo(escapeMenuMedalUi)
	mouseDetectionBox.translucent = true

	function mouseDetectionBox:relayout()
		medalHolder.medalhovered = self.containsMouse
		Ui.relayout(self)
	end

	local squadAchievements = modApi.achievements:getSquadAchievements(squad_id)
	if squadAchievements ~= nil then
		for i, achievement in ipairs(squadAchievements) do
			if i > 3 then break end
			buildAchievementUi(achievement, false)
				:addTo(achievementHolder)
		end
	end

	for islandsSecured = 2, 4 do
		buildMedal2xUi(squad_id, islandsSecured)
			:addTo(medalHolder)
	end

	setMedalTooltipText(squad_id)
	setAchievementTooltipText(squad_id)
end)

modApi.events.onEscapeMenuWindowHidden:subscribe(function()
	destroyEscapeMenuMedalUi()
end)
