
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

-- Spritesheet x offsets for medals for each difficulty
local MEDAL_X_OFFSETS = {
	EASY = -28,
	NORMAL = -53,
	HARD = -78,
	UNFAIR = -103,
	NONE = -3
}

local MEDAL_SMALL = {
	W = 19,
	H = 28,
	W_HITBOX = 19,
	H_HITBOX = 28,
}

local MEDAL_LARGE = {
	W = 42,
	H = 60,
	W_HITBOX = 42,
	H_HITBOX = 60,
	X_HANGAR = -2,
	Y_HANGAR = -2,
}

local COIN_SMALL = {
	W = 20,
	H = 20,
}

local COIN_LARGE = {
	W = 22,
	H = 22,
	X = 44,
	Y = 44,
}

local ACHIEVEMENT = {
	W = 64,
	H = 64,
	X = -1,
	Y = -1,
	W_HITBOX = 63,
	H_HITBOX = 63,
}

-- Hangar
-- ¯¯¯¯¯¯

-- Box containing medals
local HANGAR_MEDALS = {
	W = 134,
	H = 59,
	X = 30,
	Y = 29,
	X_GAP = 3, -- x gap between medals
}

-- Box containing achievements
local HANGAR_ACHIEVEMENTS = {
	W = 212,
	H = 64,
	X = 185,
	Y = 24,
	X_GAP = 11, -- x gap between achievements
}

-- Box containing both medals/achievements
local HANGAR_COMMENDATIONS = {
	W = 416,
	H = 113,
	X = 512,
	Y = 186,
}

-- Squad Selection window
-- ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

-- Box containing all squad commendations
local SQUAD_SELECT = {
	W = 635,
	H = 332,
	X = 285,
	Y = 91,
	X_GAP = 315, -- x gap between squad commendations
	Y_GAP = 68,  -- y gap between squad commendations
}

-- Box containing both medals and coins
local SQUAD_SELECT_COMMENDATIONS = {
	W = 160,
	H = 32,
}

local SQUAD_SELECT_MEDALS = {
	X_GAP = 4, -- x gap between each medal
	PADL = 8, -- left padding
	PADT = 2, -- top padding
}

local SQUAD_SELECT_COINS = {
	X_GAP = 5, -- x gap between each coin
	PADT = 4, -- top padding
}

-- Escape Menu
-- ¯¯¯¯¯¯¯¯¯¯¯

-- Box containing all commendations
local ESCAPE_MENU = {
	W = 207,
	H = 143,
	X = 362,
	Y = 60,
}

-- Box containing achievements
local ESCAPE_ACHIEVEMENTS = {
	W = ESCAPE_MENU.W - 10,
	H = ACHIEVEMENT.H,
	X = 5,
	Y = 6,
	X_GAP = 4, -- x gap between each achievement
}

-- Box containing medals
local ESCAPE_MEDALS = {
	W = ESCAPE_MENU.W,
	H = 68,
	X = 0,
	Y = -17,
	W_HITBOX = ESCAPE_MENU.W,
	H_HITBOX = 24,
	X_HITBOX = 0,
	Y_HITBOX = 96,
	X_GAP = 13, -- x gap between each medal
	PADL = 28, -- left padding
}

local function drawIfAncestorContainsMouse(self, hitboxDepth)
	local oldDrawFn = self.draw
	self.draw = function(self, screen)
		local hitbox = self

		for i = 1, hitboxDepth do
			hitbox = hitbox.parent or hitbox
		end

		local origHovered = self.hovered
		self.hovered = hitbox.containsMouse
		oldDrawFn(self, screen)
		self.hovered = origHovered
	end
end

local function clipped_draw(self, screen)
	if not self.visible then return end

	if modApi:isTipImage() then
		sdlext.occlude_draw(Ui, self, screen, sdlext.CurrentWindowRect)
	else
		Ui.draw(self, screen)
	end
end

local decoDrawHoverable = Class.inherit(DecoDraw)
function decoDrawHoverable:new(drawFunction, color, colorhl, rect)
	self.colornormal = color
	self.colorhl = colorhl
	DecoDraw.new(self, drawFunction, color, rect)
end

function decoDrawHoverable:draw(screen, widget)
	if widget.hovered then
		self.color = self.colorhl
	else
		self.color = self.colornormal
	end
	DecoDraw.draw(self, screen, widget)
end

local function buildMedalUi(surface_bucket, squad_id, islandsSecured)
	local medalData = modApi.medals:readData(squad_id)
	local difficulty = medalData[islandsSecured.."islands"]
	local w, h, offset_x
	local decoSurface = DecoSurface()

	decoSurface.draw = DecoSurfaceOutlined.draw
	decoSurface.surfacenormal = SURFACES[surface_bucket][islandsSecured].NORMAL
	decoSurface.surfacehl = SURFACES[surface_bucket][islandsSecured].HL

	if surface_bucket == "MEDALS_LARGE" then
		offset_x = MEDAL_X_OFFSETS[difficulty] * 2 + 2 -- account for 2 pixel border
		w, h = MEDAL_LARGE.W, MEDAL_LARGE.H
	else
		offset_x = MEDAL_X_OFFSETS[difficulty]
		w, h = MEDAL_SMALL.W, MEDAL_SMALL.H
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

local function buildCoinUi(surface_bucket, achievement)
	local w, h
	local surface = achievement:isComplete()
		and SURFACES[surface_bucket].ON
		or SURFACES[surface_bucket].OFF

	if surface_bucket == "COIN_LARGE" then
		w, h = COIN_LARGE.W, COIN_LARGE.H
	else
		w, h = COIN_SMALL.W, COIN_SMALL.H
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
	local borderColor = isComplete and deco.colors.achievementborder or deco.colors.buttonborder
	local decoBorder = DecoBorder(borderColor, 1, deco.colors.achievementborder, 4)

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
		:widthpx(ACHIEVEMENT.W)
		:heightpx(ACHIEVEMENT.H)
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
	local medalData = modApi.medals:readData(squad_id) or {}
	for islandsSecured = 2, 4 do
		local islandData = medalData[islandsSecured.."islands"]
		local text = nil

		if islandData then
			-- Uppercase first letter, followed by lowercase letters.
			local difficulty = medalData[islandsSecured.."islands"]:lower():gsub("^.", string.upper)
			local text_difficulty = GetText("Achievements_Medal_Island_Victory_".. difficulty)
			text = GetText("Hangar_Island_Victory_"..islandsSecured):gsub("$1", text_difficulty)
		end

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

-- Hangar Commendation Ui
-- ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
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
		self:setxpx(hangarOrigin.x + HANGAR_COMMENDATIONS.X)
		self:setypx(hangarOrigin.y + HANGAR_COMMENDATIONS.Y)
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
			:widthpx(HANGAR_COMMENDATIONS.W)
			:heightpx(HANGAR_COMMENDATIONS.H)

			:beginUi(medalHolder)
				:setVar("translucent", true)
				:widthpx(HANGAR_MEDALS.W)
				:heightpx(HANGAR_MEDALS.H)
				:setxpx(HANGAR_MEDALS.X)
				:setypx(HANGAR_MEDALS.Y)
			:endUi()

			:beginUi(achievementHolder)
				:setVar("translucent", true)
				:widthpx(HANGAR_ACHIEVEMENTS.W)
				:heightpx(HANGAR_ACHIEVEMENTS.H)
				:setxpx(HANGAR_ACHIEVEMENTS.X)
				:setypx(HANGAR_ACHIEVEMENTS.Y)
				:hgap(HANGAR_ACHIEVEMENTS.X_GAP)
				:dynamicResize(false)
			:endUi()
		:endUi()

	for islandsSecured = 2, 4 do
		if false
			or modApi:isModdedSquad(squad_id)
			or modApi.medals:isVanillaScoreCorrected(squad_id, islandsSecured)
		then
			local pos = islandsSecured - 2

			medalHolder
				:beginUi()
					:setVar("ignoreMouse", true)
					:widthpx(MEDAL_LARGE.W_HITBOX)
					:heightpx(MEDAL_LARGE.H_HITBOX)
					:setxpx(pos * (MEDAL_LARGE.W_HITBOX + HANGAR_MEDALS.X_GAP))

					:beginUi()
						:width(1):height(1)
						:setxpx(MEDAL_LARGE.X_HANGAR)
						:setypx(MEDAL_LARGE.Y_HANGAR)
						:decorate{ DecoSolid(deco.colors.framebg) }

						:beginUi(buildMedal2xUi(squad_id, islandsSecured))
							:format(drawIfAncestorContainsMouse, 3)
						:endUi()
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
						:widthpx(ACHIEVEMENT.W_HITBOX)
						:heightpx(ACHIEVEMENT.H_HITBOX)

						:beginUi(buildAchievementUi(achievement))
							:widthpx(ACHIEVEMENT.W)
							:heightpx(ACHIEVEMENT.H)
							:setxpx(ACHIEVEMENT.X)
							:setypx(ACHIEVEMENT.Y)
							:format(drawIfAncestorContainsMouse, 1)

							:beginUi(buildLargeCoinUi(achievement))
								:setxpx(COIN_LARGE.X)
								:setypx(COIN_LARGE.Y)
							:endUi()
						:endUi()
					:endUi()
			end
		end

		setAchievementTooltipText(squad_id)
	end

	setMedalTooltipText(squad_id)
	hangarMedalUi:updatePosition()
end)

modApi.events.onHangarSquadCleared:subscribe(function()
	destroyHangarMedalUi()
end)

modApi.events.onHangarLeaving:subscribe(function()
	destroyHangarMedalUi()
end)

-- Squad Selection Commendation Ui
-- ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
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
			self:setxpx(Boxes.hangar_select_big.x + SQUAD_SELECT.X)
			self:setypx(Boxes.hangar_select_big.y + SQUAD_SELECT.Y)
			self:vgap(SQUAD_SELECT.Y_GAP)
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
				:widthpx(SQUAD_SELECT.W)
				:heightpx(SQUAD_SELECT.H)
				:hgap(SQUAD_SELECT.X_GAP)
				:dynamicResize(false)
			:endUi()

		for visualIndex, squadIndex in ipairs(indices) do
			-- always added to ensure modded squads show in the right spot when vanilla squads exist
			local squadProgressUi = Ui()
				:widthpx(SQUAD_SELECT_COMMENDATIONS.W)
				:heightpx(SQUAD_SELECT_COMMENDATIONS.H)
				:addTo(flow)

			-- -1 means random or custom
			if squadIndex ~= -1 then
				-- mod loader squad index is 2 less than the true index for secret squad and above
				local modSquadIndex = squadIndex > 10 and squadIndex - 2 or squadIndex
				local trueSquadIndex = modApi.squadIndices[modSquadIndex]
				local squad_id = modApi.mod_squads[trueSquadIndex].id

				local medalHolder = Ui()
				medalHolder.squadIndex = squadIndex
				medalHolder.padt = SQUAD_SELECT_MEDALS.PADT
				medalHolder.padl = SQUAD_SELECT_MEDALS.PADL
				medalHolder.draw = draw_if_squad_unlocked

				local coinHolder = UiBoxLayout()
				coinHolder.squadIndex = squadIndex
				coinHolder.padt = SQUAD_SELECT_COINS.PADT
				coinHolder.draw = draw_if_squad_unlocked

				squadProgressUi
					:beginUi(medalHolder)
						:width(0.5)
						:height(1)
					:endUi()
					:beginUi(coinHolder)
						:width(0.5)
						:height(1)
						:pos(0.5, 0)
						:hgap(SQUAD_SELECT_COINS.X_GAP)
						:dynamicResize(false)
					:endUi()

				for islandsSecured = 2, 4 do
					if false
						or modApi:isModdedSquad(squad_id)
						or modApi.medals:isVanillaScoreCorrected(squad_id, islandsSecured)
					then
						local pos = islandsSecured - 2

						medalHolder
							:beginUi()
								:widthpx(MEDAL_SMALL.W)
								:heightpx(MEDAL_SMALL.H)
								:setxpx(pos * (MEDAL_SMALL.W_HITBOX + SQUAD_SELECT_MEDALS.X_GAP))
								:decorate{
									-- Cover up vanilla medal and recreate medal background
									DecoSolid(deco.colors.framebg),
									DecoDraw(
										screen.drawrect,
										deco.colors.buttonborder,
										sdl.rect(0,7,MEDAL_SMALL.W,2)
									),
									DecoAnchor(),
									DecoDraw(
										screen.drawrect,
										deco.colors.buttonborder,
										sdl.rect(0,16,MEDAL_SMALL.W,2)
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

-- Escape Menu Commendation Ui
-- ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
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

	escapeMenuMedalUi = Ui()
	local achievementHolder = UiBoxLayout()
	local medalHolder = Ui()
	local squad_id = GAME.additionalSquadData.squad

	function escapeMenuMedalUi:updatePosition()
		self:pospx(Boxes.escape_box.x + ESCAPE_MENU.X, Boxes.escape_box.y + ESCAPE_MENU.Y)
	end

	function escapeMenuMedalUi:onGameWindowResized(screen, oldSize)
		self:updatePosition()
	end

	function escapeMenuMedalUi:relayout()
		self.visible = true
			and sdlext.isAchievementsWindowVisible() ~= true
			and sdlext.isAbandonTimelineWindowVisible() ~= true
		Ui.relayout(self)
	end

	sdlext.getUiRoot()
		:beginUi(escapeMenuMedalUi)
			:widthpx(ESCAPE_MENU.W)
			:heightpx(ESCAPE_MENU.H)
			:setVar("translucent", true)

			:beginUi(achievementHolder)
				:widthpx(ESCAPE_ACHIEVEMENTS.W)
				:heightpx(ESCAPE_ACHIEVEMENTS.H)
				:setxpx(ESCAPE_ACHIEVEMENTS.X)
				:setypx(ESCAPE_ACHIEVEMENTS.Y)
				:hgap(ESCAPE_ACHIEVEMENTS.X_GAP)
				:setVar("translucent", true)
				:dynamicResize(false)
			:endUi()

			:beginUi()
				:widthpx(ESCAPE_MEDALS.W_HITBOX)
				:heightpx(ESCAPE_MEDALS.H_HITBOX)
				:setxpx(ESCAPE_MEDALS.X_HITBOX)
				:setypx(ESCAPE_MEDALS.Y_HITBOX)
				:setVar("translucent", true)

				:beginUi(medalHolder)
					:widthpx(ESCAPE_MEDALS.W)
					:heightpx(ESCAPE_MEDALS.H)
					:setxpx(ESCAPE_MEDALS.X)
					:setypx(ESCAPE_MEDALS.Y)
					:setVar("padl", ESCAPE_MEDALS.PADL)
					:setVar("ignoreMouse", true)
				:endUi()
			:endUi()
		:endUi()

	if modApi:isModdedSquad(squad_id) then
		local squadAchievements = modApi.achievements:getSquadAchievements(squad_id)
		if squadAchievements ~= nil then
			for i, achievement in ipairs(squadAchievements) do
				if i > 3 then break end

				achievementHolder
					:beginUi()
						:setVar("translucent", true)
						:widthpx(ACHIEVEMENT.W_HITBOX)
						:heightpx(ACHIEVEMENT.H_HITBOX)

						:beginUi(buildAchievementUi(achievement))
							:widthpx(ACHIEVEMENT.W)
							:heightpx(ACHIEVEMENT.H)
							:setxpx(ACHIEVEMENT.X)
							:setypx(ACHIEVEMENT.Y)
							:format(drawIfAncestorContainsMouse, 1)
						:endUi()
					:endUi()
			end
		end

		setAchievementTooltipText(squad_id)
	end

	for islandsSecured = 2, 4 do
		if false
			or modApi:isModdedSquad(squad_id)
			or modApi.medals:isVanillaScoreCorrected(squad_id, islandsSecured)
		then
			local pos = islandsSecured - 2

			medalHolder
				:beginUi()
					:setVar("ignoreMouse", true)
					:widthpx(MEDAL_LARGE.W_HITBOX)
					:heightpx(MEDAL_LARGE.H_HITBOX)
					:setxpx(pos * (MEDAL_LARGE.W_HITBOX + ESCAPE_MEDALS.X_GAP))
					:format(drawIfAncestorContainsMouse, 2)
					:decorate{
						-- Cover up vanilla medal and recreate medal background
						DecoSolid(deco.colors.framebg),
						decoDrawHoverable(
							screen.drawrect,
							deco.colors.buttonborder,
							deco.colors.buttonborderhl,
							sdl.rect(0,16,MEDAL_LARGE.W,2)
						),
						DecoAnchor(),
						DecoDraw(
							screen.drawrect,
							deco.colors.buttonhl,
							sdl.rect(0,18,MEDAL_LARGE.W,21)
						),
						DecoAnchor(),
						decoDrawHoverable(
							screen.drawrect,
							deco.colors.buttonborder,
							deco.colors.buttonborderhl,
							sdl.rect(0,39,MEDAL_LARGE.W,2)
						),
					}
					:beginUi(buildMedal2xUi(squad_id, islandsSecured))
						:format(drawIfAncestorContainsMouse, 3)
					:endUi()
				:endUi()
		end
	end

	setMedalTooltipText(squad_id)
	escapeMenuMedalUi:updatePosition()
end)

modApi.events.onEscapeMenuWindowHidden:subscribe(function()
	destroyEscapeMenuMedalUi()
end)
