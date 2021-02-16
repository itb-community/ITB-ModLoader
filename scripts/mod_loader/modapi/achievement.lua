
local canAddAchievements = true

local function initData()
	if modApi.achievements.cachedSavedata ~= nil then return end

	sdlext.config(
		"modcontent.lua",
		function(obj)
			obj.achievements = obj.achievements or {}
			modApi.achievements.cachedSavedata = obj.achievements
		end
	)
end

-- writes achievement data.
local function writeData(mod_id, achievement_id, obj)
	assert(type(mod_id) == 'string')
	assert(type(achievement_id) == 'string')

	initData()

	sdlext.config(
		"modcontent.lua",
		function(readObj)
			readObj.achievements[mod_id][achievement_id] = obj
			modApi.achievements.cachedSavedata = readObj.achievements
		end
	)
end

-- reads achievement data.
local function readData(mod_id, achievement_id)
	assert(type(mod_id) == 'string')
	assert(type(achievement_id) == 'string')

	initData()

	if modApi.achievements.cachedSavedata[mod_id] then
		return modApi.achievements.cachedSavedata[mod_id][achievement_id]
	end

	return nil
end

local AchievementDictionary = {
	_mods = {},
	add = function(self, mod_id, achievement_id, achievement)
		assert(type(mod_id) == 'string')
		assert(type(achievement_id) == 'string')
		assert(type(achievement) == 'table')

		self._mods[mod_id] = self._mods[mod_id] or {}
		self._mods[mod_id][achievement_id] = achievement
	end,

	get = function(self, mod_id, achievement_id)
		if self._mods[mod_id] == nil then
			return nil
		end

		return self._mods[mod_id][achievement_id]
	end,
}

local Achievement = {}
CreateClass(Achievement)

function Achievement:addReward() end
function Achievement:remReward() end

function Achievement:trigger(progress)
	if IsTestMechScenario() then return end

	if type(progress) == 'table' and type(self.objective) == 'table' then
		self:addProgress(progress)
		return
	end

	local isComplete = progress ~= false
	local data

	if type(self.objective) == 'table' then
		if isComplete then
			data = shallow_copy(self.objective)
		else
			data = self:getResetObjective()
		end
	else
		data = isComplete
	end

	local wasComplete = self:isComplete()
	writeData(self.mod_id, self.id, data)

	if isComplete and not wasComplete then
		modApi.toasts:add(self)
		self:addReward()
	elseif not isComplete and wasComplete then
		self:remReward()
	end
end

function Achievement:addProgress(progress)
	if IsTestMechScenario() then return end

	if type(progress) ~= 'table' or type(self.objective) ~= 'table' then
		return
	end

	local completed = true
	local status = self:getStatus()

	for id, new_progress in pairs(progress) do
		Assert.Equals(type(new_progress), type(status[id]), "Achievement status type mismatch")

		if type(progress[id]) == 'number' then
			status[id] = status[id] + new_progress
		else
			status[id] = status[id] or new_progress
		end
	end

	writeData(self.mod_id, self.id, status)

	if self:isObjectiveComplete() then
		self:trigger()
	end
end

function Achievement:isComplete(objective_id)
	local status = self:getStatus()

	if objective_id == nil then
		local isComplete = true

		if type(status) == 'table' then
			for objective_id, _ in pairs(status) do
				isComplete = isComplete and self:isComplete(objective_id)
			end
		else
			isComplete = status == true
		end

		return isComplete
	else
		local goal = self.objective[objective_id]
		if type(goal) == 'number' then
			return status[objective_id] >= goal
		else
			return status[objective_id] == goal
		end
	end
end

function Achievement:isProgress(goal, objective_id)
	local status = self:getStatus()

	if objective_id == nil then
		local isProgress = true

		if type(goal) == 'table' then
			for objective_id, _ in pairs(goal) do
				isProgress = isProgress and self:isProgress(goal[objective_id], objective_id)
			end
		else
			isProgress = status == goal
		end

		return isProgress
	else
		if type(status) == 'number' then
			return goal >= status[objective_id]
		else
			return goal == status[objective_id]
		end
	end
end

function Achievement:getStatus()
	return shallow_copy(readData(self.mod_id, self.id))
end

function Achievement:getResetObjective()
	if type(self.objective) == 'table' then
		local resetObjective = {}

		for id, obj in pairs(self.objective) do
			Assert.Equals({'number', 'boolean', 'string'}, type(obj), "Objective for achievement with id ".. id .." for mod with id ".. self.mod_id)
			if type(obj) == 'number' then
				resetObjective[id] = 0
			else
				resetObjective[id] = false
			end
		end

		return resetObjective
	end

	return false
end

function Achievement:getTooltip()
	local tooltip = self.tooltip
	if type(self.objective) == 'table' then
		for obj_id, obj in pairs(self.objective) do
			local obj_type = type(obj)
			local obj_status = self:getStatus()[obj_id]

			if obj_type == 'number' then
				tooltip = tooltip:gsub("$".. obj_id, obj_status .."/".. obj)

			elseif obj_type == 'boolean' then
				tooltip = tooltip:gsub("$".. obj_id, obj_status and "Complete" or "Incomplete")

			elseif obj_type == 'string' then
				undone, done = obj:match("(.+)|(.+)")
				tooltip = tooltip:gsub("$".. obj_id, obj_status and done or undone)
			end
		end
	end

	return tooltip
end

local function buildAchievementId()
	local mod_id = modApi.currentMod
	local achievements = AchievementDictionary._mods[mod_id]

	if achievements ~= nil then
		local i = 2
		while achievements[mod_id..i] ~= nil do
			i = i + 1
		end

		return mod_id..i
	end

	return mod_id
end

local function buildAchievementName()
	local mod = mod_loader.mods[modApi.currentMod]
	return mod.name
end

local function buildAchievementObjective(objective)
	if objective == nil then
		return true
	end

	return objective
end

-- migrate achievements from lmn_achievements.chievos
local function migrateAchievements()
	local mods = lmn_achievements.chievos

	for mod_id, achievements in pairs(mods) do
		for _, old_achievement in ipairs(achievements) do
			achievement = Achievement:new(old_achievement)
			achievement.mod_id = mod_id
			modApi.achievements:add(achievement)
		end
	end
end

local function triggerRewards()
	local mods = lmn_achievements.chievos

	for mod_id, achievements in pairs(mods) do
		for _, achievement in ipairs(achievements) do
			if achievement:isComplete() then
				achievement:addReward()
			end
		end
	end
end

local function onModsInitialized()
	migrateAchievements()
	triggerRewards()

	canAddAchievements = false
end

local function addAchievement(self, achievement)
	Assert.True(self:canBeAdded(), "Cannot add achievements after game init")
	Assert.Equals('table', type(achievement), "Argument #1")

	local mod_id = modApi.currentMod or achievement.mod_id
	local id = achievement.id or buildAchievementId()
	local name = achievement.name or buildAchievementName()
	local tooltip = achievement.tooltip or achievement.tip or ""
	local image = achievement.image or achievement.img
	local objective = buildAchievementObjective(achievement.objective)
	local addReward = achievement.addReward
	local remReward = achievement.remReward

	Assert.Equals({'nil', 'string'}, type(mod_id), "mod_id of achievement")
	Assert.Equals({'nil', 'string'}, type(id), "id of achievement")
	Assert.Equals({'nil', 'string'}, type(name), "name of achievement")
	Assert.Equals({'nil', 'string'}, type(image), "image of achievement")
	Assert.Equals({'boolean', 'table'}, type(objective), "objective of achievement")
	Assert.Equals({'nil', 'function'}, type(addReward), "add reward function of achievement")
	Assert.Equals({'nil', 'function'}, type(remReward), "rem reward function of achievement")

	local data = Achievement:new{
		mod_id = mod_id,
		id = id,
		name = name,
		tooltip = tooltip,
		image = image,
		objective = objective,
		addReward = addReward,
		remReward = remReward,
	}

	Assert.Equals('nil', type(AchievementDictionary:get(mod_id, id)), "Achievement for mod ".. mod_id .." with id ".. id .." already exists")

	AchievementDictionary:add(mod_id, id, data)

	local currentData = readData(mod_id, id)
	writeData(mod_id, id, currentData or data:getResetObjective())
end

local function assertIsAchievement(mod_id, achievement_id)
	Assert.Equals('string', type(mod_id), "Argument #1")
	Assert.Equals('string', type(achievement_id), "Argument #2")
	Assert.NotEquals('nil', type(AchievementDictionary:get(mod_id, achievement_id)), "Achievement for mod ".. mod_id .." with id ".. achievement_id .." does not exist")
end

local function getAchievement(self, mod_id, achievement_id)
	if mod_id and achievement_id then
		assertIsAchievement(mod_id, achievement_id)
		return AchievementDictionary:get(mod_id, achievement_id)
	end

	if mod_id then
		Assert.Equals('string', type(mod_id), "Argument #1")
		return shallow_copy(AchievementDictionary._mods[mod_id])
	end

	return shallow_copy(AchievementDictionary._mods)
end

local function triggerAchievement(self, mod_id, achievement_id, status)
	assertIsAchievement(mod_id, achievement_id)
	local achievement = AchievementDictionary:get(mod_id, achievement_id)
	achievement:trigger(status)
end

local function addAchievementProgress(self, mod_id, achievement_id, progress)
	assertIsAchievement(mod_id, achievement_id)
	local achievement = AchievementDictionary:get(mod_id, achievement_id)
	achievement:addProgress(progress)
end

local function isAchievementComplete(self, mod_id, achievement_id)
	assertIsAchievement(mod_id, achievement_id)
	local achievement = AchievementDictionary:get(mod_id, achievement_id)
	return achievement:isComplete()
end

local function isAchievementStatus(self, mod_id, achievement_id, status)
	assertIsAchievement(mod_id, achievement_id)
	local achievement = AchievementDictionary:get(mod_id, achievement_id)
	return achievement:isStatus(status)
end

local function getAchievementStatus(self, mod_id, achievement_id)
	assertIsAchievement(mod_id, achievement_id)
	local achievement = AchievementDictionary:get(mod_id, achievement_id)
	return achievement:getStatus()
end

local function achievementsCanBeAdded(self)
	return canAddAchievements
end

modApi.achievements = {
	add = addAchievement,
	get = getAchievement,
	trigger = triggerAchievement,
	addprogress = addAchievementProgress,
	isComplete = isAchievementComplete,
	isStatus = isAchievementStatus,
	getStatus = getAchievementStatus,
	canBeAdded = achievementsCanBeAdded
}

modApi.events.onModsInitialized:subscribe(onModsInitialized)
