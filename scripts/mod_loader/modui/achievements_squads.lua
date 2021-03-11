
local NO_ICON = "img/achievements/No_Icon.png"
local MEDAL_OFFSETS_X = {
	EASY = -29,
	NORMAL = -54,
	HARD = -79,
	NONE = -4
}
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
	local w, h = 15, 24

	if surface_bucket == "MEDALS_LARGE" then
		offset_x = offset_x * 2
		w, h = 34, 52
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
	if modApi:isTipImage() then
		sdlext.occlude_draw(Ui, self, screen, sdlext.CurrentWindowRect)
	else
		Ui.draw(self, screen)
	end
end

local function buildCoinUi(surface_bucket, achievement)
	local surface = achievement:isComplete() and SURFACES[surface_bucket].ON or SURFACES[surface_bucket].OFF
	local w, h = 20, 20

	if surface_bucket == "COIN_LARGE" then
		w, h = 22, 22
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
		:widthpx(64)
		:heightpx(64)
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
			:pospx(44, 47)
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
		:widthpx(367)
		:heightpx(67)
		:addTo(root)

	function hangarMedalUi:relayout()
		local hangarOrigin = GetHangarOrigin()
		self:pospx(hangarOrigin.x + 541, hangarOrigin.y + 209)
		self.visible = sdlext.isHangar() and IsHangarWindowlessState()
		Ui.relayout(self)
	end

	hangarMedalUi.translucent = true
	hangarMedalUi:relayout()

	medalHolder = UiBoxLayout()
		:widthpx(135)
		:heightpx(60)
		:setypx(5)
		:hgap(11)
		:dynamicResize(false)
		:padding(3)
		:addTo(hangarMedalUi)
	medalHolder.translucent = true

	achievementHolder = UiBoxLayout()
		:widthpx(212)
		:heightpx(64)
		:setxpx(155)
		:hgap(10)
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
local squadSelectionMedalUi
local function destroySquadSelectionMedalUi()
	if squadSelectionMedalUi ~= nil then
		squadSelectionMedalUi:detach()
		squadSelectionMedalUi = nil
	end
end

modApi.events.onSquadSelectionWindowShown:subscribe(function()
	destroySquadSelectionMedalUi()
	loadSquadSelection()

	local root = sdlext.getUiRoot()
	squadSelectionMedalUi = UiFlowLayout()
		:widthpx(635)
		:heightpx(303)
		:hgap(315)
		:vgap(69)
		:dynamicResize(false)
		:addTo(root)

	function squadSelectionMedalUi:relayout()
		self:pospx(Boxes.hangar_select_big.x + 285, Boxes.hangar_select_big.y + 60)
		self.visible = not sdlext.isAchievementsWindowVisible()
		UiFlowLayout.relayout(self)
	end

	squadSelectionMedalUi.ignoreMouse = true
	squadSelectionMedalUi:relayout()

	for squadIndex = 1, 8 do
		local squad_index = modApi.squadIndices[squadIndex]
		local squad_id = modApi.mod_squads[squad_index].id

		local squadProgressUi = Ui()
			:widthpx(160)
			:heightpx(24)
			:addTo(squadSelectionMedalUi)

		if modApi:isModdedSquad(squad_id) then

			local medalHolder = UiBoxLayout()
				:width(0.5)
				:height(1)
				:hgap(8)
				:dynamicResize(false)
				:addTo(squadProgressUi)
			medalHolder.padl = 10

			local coinHolder = UiBoxLayout()
				:width(0.5)
				:heightpx(20)
				:pos(0.5, 0)
				:hgap(5)
				:dynamicResize(false)
				:addTo(squadProgressUi)

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
		:widthpx(208)
		:heightpx(135)
		:addTo(root)

	function escapeMenuMedalUi:relayout()
		self:pospx(Boxes.escape_box.x + 354, Boxes.escape_box.y + 60)
		self.visible = not sdlext.isAchievementsWindowVisible()    and
		               not sdlext.isAbandonTimelineWindowVisible()
		Ui.relayout(self)
	end

	escapeMenuMedalUi.translucent = true
	escapeMenuMedalUi:relayout()

	local achievementHolder = UiBoxLayout()
		:width(1)
		:heightpx(74)
		:hgap(3)
		:padding(5)
		:dynamicResize(false)
		:addTo(escapeMenuMedalUi)
	achievementHolder.translucent = true

	local medalHolder = UiBoxLayout()
		:width(1)
		:heightpx(52)
		:setypx(83)
		:hgap(21)
		:dynamicResize(false)
		:addTo(escapeMenuMedalUi)
	medalHolder.padl = 33
	medalHolder.ignoreMouse = true

	local mouseDetectionBox = Ui()
		:width(1)
		:heightpx(25)
		:setypx(95)
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
