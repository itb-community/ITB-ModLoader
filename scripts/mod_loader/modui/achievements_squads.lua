
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

local MEDAL_OFFSETS_X = {
	EASY = -29,
	NORMAL = -54,
	HARD = -79,
	NONE = -4
}

-- UI measurements
local UI = {
	MEDAL = {
		SMALL = {
			WIDTH = 15,
			HEIGHT = 24
		},
		LARGE = {
			WIDTH = 34,
			HEIGHT = 52
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
			X = 44,
			Y = 47
		}
	},
	ACHIEVEMENT = {
		WIDTH = 64,
		HEIGHT = 64
	},
	HANGAR = {
		WIDTH = 367,
		HEIGHT = 67,
		X_OFFSET = 541,
		Y_OFFSET = 209,
		MEDAL_HOLDER = {
			WIDTH = 135,
			HEIGHT = 60,
			Y = 5,
			HORIZONTAL_GAP = 11,
			PADDING_ALL = 3
		},
		ACHIEVEMENT_HOLDER = {
			WIDTH = 212,
			HEIGHT = 64,
			X = 155,
			HORIZONTAL_GAP = 10
		}
	},
	SQUAD_SELECT = {
		WIDTH = 635,
		HEIGHT = 303,
		HORIZONTAL_GAP = 315,
		VERTICAL_GAP = {
			SMALL_UI = 76,
			LARGE_UI = 69
		},
		X_OFFSET = 285,
		Y_OFFSET = {
			SMALL_UI = 95,
			LARGE_UI = 60
		},
		PROGRESS = {
			WIDTH = 160,
			HEIGHT = 24,
			MEDAL_HOLDER = {
				HORIZONTAL_GAP = 8,
				PADDING_LEFT = 9
			},
			COIN_HOLDER = {
				HEIGHT = 20,
				HORIZONTAL_GAP = 5
			}
		}
	},
	ESCAPE_MENU = {
		WIDTH = 208,
		HEIGHT = 135,
		X_OFFSET = 354,
		Y_OFFSET = 60,
		MEDAL_HOLDER = {
			HEIGHT = 52,
			Y = 83,
			HORIZONTAL_GAP = 21,
			PADDING_LEFT = 33,
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

local function medal_deco_draw(self, screen, widget)
	if widget.parent.medalhovered then
		self.surface = self.surface_hl
	else
		self.surface = self.surface_normal
	end

	DecoSurface.draw(self, screen, widget)
end

local function buildMedalUi(surface_bucket, squad_id, islandsSecured)
	local deco = DecoSurface()
	deco.draw = medal_deco_draw
	deco.surface_normal = SURFACES[surface_bucket][islandsSecured].NORMAL
	deco.surface_hl = SURFACES[surface_bucket][islandsSecured].HL

	local medalData = modApi.medals:readData(squad_id)
	local difficulty = medalData[islandsSecured.."islands"]
	local offset_x = MEDAL_OFFSETS_X[difficulty]
	local w, h = UI.MEDAL.SMALL.WIDTH, UI.MEDAL.SMALL.HEIGHT

	if surface_bucket == "MEDALS_LARGE" then
		offset_x = offset_x * 2
		w, h = UI.MEDAL.LARGE.WIDTH, UI.MEDAL.LARGE.HEIGHT
	end

	local medal = Ui()
		:widthpx(w)
		:heightpx(h)
		:decorate{ DecoAlign(offset_x, 0), deco }
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

local function buildAchievementUi(achievement, drawCoin)
	local isComplete = achievement:isComplete()
	local surface = sdlext.getSurface{
		path = achievement.image or NO_ICON,
		transformations = { { grayscale = not isComplete } }
	}

	local ui = Ui()
		:widthpx(UI.ACHIEVEMENT.WIDTH)
		:heightpx(UI.ACHIEVEMENT.HEIGHT)
		:decorate({
			DecoSurface(surface, "center", "center"),
			DecoAnchor(),
			DecoSolid(isComplete and deco.colors.transparent or deco.colors.halfblack),
			DecoAnchor(),
			DecoBorder(isComplete and deco.colors.achievementborder or deco.colors.buttonborder, 1, deco.colors.achievementborder, 4)
		})
	ui.translucent = true
	ui.clipRect = sdl.rect(0,0,0,0)
	ui.draw = clipped_draw

	if drawCoin then
		buildLargeCoinUi(achievement)
			:pospx(UI.COIN.LARGE.X, UI.COIN.LARGE.Y)
			:addTo(ui)
	end

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

	if not modApi:isModdedSquad(squad_id) then
		return
	end

	local root = sdlext.getUiRoot()
	hangarMedalUi = Ui()
		:widthpx(UI.HANGAR.WIDTH)
		:heightpx(UI.HANGAR.HEIGHT)
		:addTo(root)

	function hangarMedalUi:relayout()
		local hangarOrigin = GetHangarOrigin()
		self:pospx(hangarOrigin.x + UI.HANGAR.X_OFFSET, hangarOrigin.y + UI.HANGAR.Y_OFFSET)
		self.visible = sdlext.isHangar() and IsHangarWindowlessState()
		Ui.relayout(self)
	end

	hangarMedalUi.translucent = true
	hangarMedalUi:relayout()

	medalHolder = UiBoxLayout()
		:widthpx(UI.HANGAR.MEDAL_HOLDER.WIDTH)
		:heightpx(UI.HANGAR.MEDAL_HOLDER.HEIGHT)
		:setypx(UI.HANGAR.MEDAL_HOLDER.Y)
		:hgap(UI.HANGAR.MEDAL_HOLDER.HORIZONTAL_GAP)
		:dynamicResize(false)
		:padding(UI.HANGAR.MEDAL_HOLDER.PADDING_ALL)
		:addTo(hangarMedalUi)
	medalHolder.translucent = true

	achievementHolder = UiBoxLayout()
		:widthpx(UI.HANGAR.ACHIEVEMENT_HOLDER.WIDTH)
		:heightpx(UI.HANGAR.ACHIEVEMENT_HOLDER.HEIGHT)
		:setxpx(UI.HANGAR.ACHIEVEMENT_HOLDER.X)
		:hgap(UI.HANGAR.ACHIEVEMENT_HOLDER.HORIZONTAL_GAP)
		:dynamicResize(false)
		:addTo(hangarMedalUi)
	achievementHolder.translucent = true

	function medalHolder:relayout()
		self.medalhovered = self.containsMouse
		UiBoxLayout.relayout(self)
	end

	for islandsSecured = 2, 4 do
		buildMedal2xUi(squad_id, islandsSecured)
			:addTo(medalHolder)
	end

	local squadAchievements = modApi.achievements:getSquadAchievements(squad_id)
	if squadAchievements ~= nil then
		for i, achievement in ipairs(squadAchievements) do
			if i > 3 then break end
			buildAchievementUi(achievement, true)
				:addTo(achievementHolder)
		end
	end

	setMedalTooltipText(squad_id)
	setAchievementTooltipText(squad_id)
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
		if Boxes.hangar_select_big.x == sdlext.CurrentWindowRect.x and Boxes.hangar_select_big.y == sdlext.CurrentWindowRect.y + 10 then
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

	local flow = UiFlowLayout()
		:widthpx(UI.SQUAD_SELECT.WIDTH)
		:heightpx(UI.SQUAD_SELECT.HEIGHT)
		:hgap(UI.SQUAD_SELECT.HORIZONTAL_GAP)
		:dynamicResize(false)
		:addTo(squadSelectionMedalUi)

	function flow:relayout()
		local vgap
		local yOffset

		if modApi:isSecretSquadAvailable() then
			vgap = UI.SQUAD_SELECT.VERTICAL_GAP.LARGE_UI
			yOffset = UI.SQUAD_SELECT.Y_OFFSET.LARGE_UI
		else
			vgap = UI.SQUAD_SELECT.VERTICAL_GAP.SMALL_UI
			yOffset = UI.SQUAD_SELECT.Y_OFFSET.SMALL_UI
		end

		if self.gapVertical ~= vgap then
			self:vgap(vgap)
		end

		self:pospx(Boxes.hangar_select_big.x + UI.SQUAD_SELECT.X_OFFSET, Boxes.hangar_select_big.y + yOffset)
		self.visible = not sdlext.isAchievementsWindowVisible()
		UiFlowLayout.relayout(self)
	end

	flow.ignoreMouse = true
	flow:relayout()

	for squadIndex = 1, 8 do
		local squad_index = modApi.squadIndices[squadIndex]
		local squad_id = modApi.mod_squads[squad_index].id

		local squadProgressUi = Ui()
			:widthpx(UI.SQUAD_SELECT.PROGRESS.WIDTH)
			:heightpx(UI.SQUAD_SELECT.PROGRESS.HEIGHT)
			:addTo(flow)

		if modApi:isModdedSquad(squad_id) then

			local medalHolder = UiBoxLayout()
				:width(0.5)
				:height(1)
				:hgap(UI.SQUAD_SELECT.PROGRESS.MEDAL_HOLDER.HORIZONTAL_GAP)
				:dynamicResize(false)
				:addTo(squadProgressUi)
			medalHolder.padl = UI.SQUAD_SELECT.PROGRESS.MEDAL_HOLDER.PADDING_LEFT
			medalHolder.squadIndex = squadIndex
			medalHolder.draw = draw_if_squad_unlocked

			local coinHolder = UiBoxLayout()
				:width(0.5)
				:heightpx(UI.SQUAD_SELECT.PROGRESS.COIN_HOLDER.HEIGHT)
				:pos(0.5, 0)
				:hgap(UI.SQUAD_SELECT.PROGRESS.COIN_HOLDER.HORIZONTAL_GAP)
				:dynamicResize(false)
				:addTo(squadProgressUi)
			coinHolder.squadIndex = squadIndex
			coinHolder.draw = draw_if_squad_unlocked

			for islandsSecured = 2, 4 do
				buildMedal1xUi(squad_id, islandsSecured)
					:addTo(medalHolder)
			end

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
