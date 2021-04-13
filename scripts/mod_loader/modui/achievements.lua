
local NO_ICON = "img/achievements/No_Icon.png"
local ICON_SIZE = 64
local ICON_PAD_TOP = 9
local ICON_PAD_BOTTOM = 9
local ICON_PAD_LEFT = 8
local ICON_PAD_RIGHT = 4
local CONTENT_GAP = 8
local FRAME_PAD_TOP = 28
local FRAME_PAD_LEFT = 33
local FRAME_WIDTH = 1010
local FRAME_HEIGHT = 643
local SQUAD_WINDOW_W = 559
local SQUAD_BOX_W = 228
local GLOBAL_WINDOW_W = 445
local GLOBAL_BOX_W = 369

local achievementFrames

local function enableAchievementFrame(frame, isComplete)
	local data = frame.data
	if isComplete then
		data.deco_surface.surface = sdlext.getSurface({
										path = data.image or NO_ICON,
										transformations = { { grayscale = false } }
									})
		data.deco_halfblack.color = deco.colors.transparent
		data.deco_border.bordercolor = deco.colors.achievementborder
	else
		data.deco_surface.surface = sdlext.getSurface({
										path = data.image or NO_ICON,
										transformations = { { grayscale = true } }
									})
		data.deco_halfblack.color = deco.colors.halfblack
		data.deco_border.bordercolor = deco.colors.buttonborder
	end
end

local function onClickedAchievement(self, button)
	if button == 1 then
		local achievement = self.data.achievement
		local isComplete = self.checked

		enableAchievementFrame(self, isComplete)
		return true
	end

	return false
end

local function buildAchievementFrame(achievement)
	local deco_surface = DecoSurface(nil, "center", "center")
	local deco_halfblack = DecoSolid(deco.colors.halfblack)
	local deco_border = DecoBorder(deco.colors.buttonborder, 1, deco.colors.achievementborder, 4)
	local isComplete = achievement:isComplete()

	local frame
	if modApi.developmentMode then
		frame = UiCheckbox()
		frame.onclicked = onClickedAchievement
	else
		frame = Ui()
	end

	frame
		:widthpx(ICON_SIZE)
		:heightpx(ICON_SIZE)
		:settooltip(achievement:getTooltip(), achievement.name, true)
		:decorate({
			deco_surface,
			DecoAnchor(),
			deco_halfblack,
			DecoAnchor(),
			deco_border
		})
	frame.data = {
		achievement = achievement,
		image = achievement.image,
		deco_surface = deco_surface,
		deco_halfblack = deco_halfblack,
		deco_border = deco_border
	}
	frame.checked = isComplete

	enableAchievementFrame(frame, isComplete)
	table.insert(achievementFrames, frame)

	return frame
end

local function buildModContent(name, widthpx, modAchievements)

	local container = UiBoxLayout()
		:widthpx(widthpx)
		:vgap(5)
		:decorate({
			DecoFrame(deco.colors.button)
		})
	container.padt = ICON_PAD_TOP
	container.padb = ICON_PAD_BOTTOM
	container.padl = ICON_PAD_LEFT
	container.padr = ICON_PAD_RIGHT

	local header = Ui()
		:width(1)
		:heightpx(16)
		:decorate({ DecoAlignedText(name, deco.fonts.labelfont, nil, "center", "top") })
		:addTo(container)

	local content = UiFlowLayout()
		:width(1)
		:vgap(CONTENT_GAP):hgap(CONTENT_GAP)
		:addTo(container)
	content.nofitx = true
	content.nofity = true

	for _, achievement in ipairs(modAchievements) do
		buildAchievementFrame(achievement)
			:addTo(content)
	end

	return container
end

local function buildAchievementsFrameContent(scroll)
	local allAchievements = modApi.achievements:get()
	local allSquadAchievements = {}
	local allGlobalAchievements = {}

	for mod_id, modAchievements in pairs(allAchievements) do
		for _, achievement in ipairs(modAchievements) do
			local squad_id = achievement.squad
			if squad_id then
				allSquadAchievements[squad_id] = allSquadAchievements[squad_id] or {}
				table.insert(allSquadAchievements[squad_id], achievement)
			else
				allGlobalAchievements[mod_id] = allGlobalAchievements[mod_id] or {}
				table.insert(allGlobalAchievements[mod_id], achievement)
			end
		end
	end

	scroll.padt = 0
	scroll.padb = 0
	scroll.padl = 0
	scroll.padr = 0

	local holder = UiBoxLayout()
		:height(1)
		:hgap(0)
		:addTo(scroll)

	-- Squad based achievements
	local ui_squads = Ui()
		:widthpx(SQUAD_WINDOW_W)
		:height(1)
		:addTo(holder)

	local label_squads = Ui()
		:width(1):height(1)
		:setTranslucent(true)
		:decorate({
			DecoLabel("Squad Based", {
				extraWidth = 4,
				textOffsetX = 3
			})
		})
		:addTo(ui_squads)

	local scroll_squads = UiScrollArea()
		:width(1):height(1)
		:addTo(ui_squads)

	local content_squads = UiFlowLayout()
		:width(1)
		:hgap(40)
		:vgap(5)
		:addTo(scroll_squads)
	content_squads.padt = FRAME_PAD_TOP
	content_squads.padl = FRAME_PAD_LEFT

	for squad_id, squadAchievements in pairs(allSquadAchievements) do
		local mod_id = squadAchievements[1].mod_id
		local mod = mod_loader.mods[mod_id]
		local name = mod.name
		local squad = modApi.mod_squads_by_id[squad_id]

		if squad then
			name = squad[1]
		end

		buildModContent(name, SQUAD_BOX_W, squadAchievements)
			:addTo(content_squads)
	end

	local line = Ui()
		:widthpx(scroll.parent.decorations[1].bordersize)
		:height(1)
		:decorate({ DecoSolid(scroll.parent.decorations[1].bordercolor) })
		:addTo(holder)

	-- Global achievements
	local ui_global = Ui()
		:widthpx(GLOBAL_WINDOW_W)
		:height(1)
		:addTo(holder)

	local label_global = Ui()
		:width(1):height(1)
		:setTranslucent(true)
		:decorate({
			DecoLabel("Global", {
				extraWidth = 7,
				textOffsetX = 4
			})
		})
		:addTo(ui_global)

	local scroll_global = UiScrollArea()
		:width(1):height(1)
		:addTo(ui_global)

	local content_global = UiFlowLayout()
		:width(1)
		:vgap(5)
		:addTo(scroll_global)
	content_global.padt = FRAME_PAD_TOP
	content_global.padl = FRAME_PAD_LEFT

	for mod_id, modAchievements in pairs(allGlobalAchievements) do
		local mod = mod_loader.mods[mod_id]
		buildModContent(mod.name, GLOBAL_BOX_W, modAchievements)
			:addTo(content_global)
	end
end

local function onExit()
	sdlext.config(
		modApi:getCurrentProfilePath().."modcontent.lua",
		function(obj)
			obj.achievements = obj.achievements or {}
			for _, frame in ipairs(achievementFrames) do
				local achievement = frame.data.achievement
				local mod_id = achievement.mod_id
				local id = achievement.id
				local isComplete = achievement:isComplete()

				obj.achievements[mod_id] = obj.achievements[mod_id] or {}
				if frame.checked ~= isComplete then
					if isComplete then
						obj.achievements[mod_id][id] = achievement:getObjectiveInitialState()
						achievement:remReward()
					else
						obj.achievements[mod_id][id] = achievement:getObjectiveCompleteState()
						achievement:addReward()
					end
				end
			end

			modApi.achievements.cachedProfileData = obj.achievements
		end
	)

	achievementFrames = nil
end

local function showAchievementUi()
	achievementFrames = {}

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = sdlext.buildScrollDialog(
			GetText("Achievements_FrameTitle"),
			buildAchievementsFrameContent,
			{
				minW = FRAME_WIDTH,
				maxW = FRAME_WIDTH,
				minH = FRAME_HEIGHT,
				maxH = FRAME_HEIGHT,
				separateHeader = true
			}
		)

		frame:addTo(ui)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2 - 6)
	end)
end

function DisplayAchievements()
	showAchievementUi(root)
end
