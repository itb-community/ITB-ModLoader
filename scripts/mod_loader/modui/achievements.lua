
local NO_ICON = "img/achievements/No_Icon.png"
local ICON_COUNT_PER_ROW = 8
local ICON_SIZE = 64
local ICON_PADDING = 6
local CONTENT_GAP = 5
local FRAME_PADDING = 25

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

local function buildModContent(mod, modAchievements)

	local container = UiBoxLayout()
		:width(1)
		:vgap(5)
		:padding(ICON_PADDING)
		:decorate({
			DecoFrame(deco.colors.button)
		})

	local header = Ui()
		:width(1)
		:heightpx(20)
		:decorate({
			DecoAlign(0, 2),
			DecoAlignedText(mod.name, nil, nil, "center", "top")
		})
		:addTo(container)

	local content = UiFlowLayout()
		:width(1)
		:vgap(CONTENT_GAP):hgap(CONTENT_GAP)
		:addTo(container)
	content.nofitx = true
	content.nofity = true

	for _, achievement in pairs(modAchievements) do
		buildAchievementFrame(achievement)
			:addTo(content)
	end

	return container
end

local function buildAchievementsFrameContent(scroll)
	local allAchievements = modApi.achievements:get()

	local content = UiBoxLayout()
		:width(1)
		:vgap(5)
		:padding(FRAME_PADDING)
		:addTo(scroll)

	for mod_id, modAchievements in pairs(allAchievements) do
		local mod = mod_loader.mods[mod_id]
		buildModContent(mod, modAchievements)
			:addTo(content)
	end
end

local function buildAchievementsFrameButtons()

end

local function onExit()
	sdlext.config(
		"modcontent.lua",
		function(obj)
			obj.achievements = obj.achievements or {}
			for _, frame in ipairs(achievementFrames) do
				local achievement = frame.data.achievement
				local mod_id = achievement.mod_id
				local id = achievement.id
				local isComplete = achievement:isComplete()

				obj.achievements[mod_id] = obj.achievements[mod_id] or {}
				if frame.checked and not isComplete then
					obj.achievements[mod_id][id] = shallow_copy(achievement.objective)
					achievement:addReward()
				elseif not frame.checked and isComplete then
					obj.achievements[mod_id][id] = achievement:getResetObjective()
					achievement:remReward()
				end
			end

			modApi.achievements.cachedSavedata = obj.achievements
		end
	)

	achievementFrames = nil
end

local function showAchievementUi()
	achievementFrames = {}

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = sdlext.buildButtonDialog(
			GetText("Achievements_FrameTitle"),
			0.6 * ScreenSizeX(), 0.8 * ScreenSizeY(),
			buildAchievementsFrameContent,
			buildAchievementsFrameButtons
		)

		frame:addTo(ui)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
	end)
end

function DisplayAchievements()
	showAchievementUi(root)
end
