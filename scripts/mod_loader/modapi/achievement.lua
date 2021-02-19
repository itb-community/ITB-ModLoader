
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
		table.insert(self._mods[mod_id], achievement)
	end,

	get = function(self, mod_id, achievement_id_or_index)
		Assert.Equals('string', type(mod_id), "Argument #1")
		Assert.Equals({'number', 'string'}, type(achievement_id_or_index), "Argument #2")

		if self._mods[mod_id] == nil then
			return nil
		end

		if type(achievement_id_or_index) == 'string' then
			local achievement_id = achievement_id_or_index
			for _, achievement in ipairs(self._mods[mod_id]) do
				if achievement.id == achievement_id then
					return achievement
				end
			end
		end

		local achievement_index = achievement_id_or_index
		return self._mods[mod_id][achievement_index]
	end,
}

local function assertIsCompatibleObjectiveType(measure, target, measure_name)
	local msg = "Objective compatibility type check failed"
	measure_name = measure_name and " for '".. measure_name .."." or ""

	if type(target) == 'boolean' or type(target) == 'string' then
		Assert.Equals('boolean', type(measure), msg .. measure_name)
	else
		Assert.Equals(type(target), type(measure), msg .. measure_name)

		if type(target) == 'table' then
			for i, _ in pairs(measure) do
				assertIsCompatibleObjectiveType(measure[i], target[i], i)
			end
		end
	end
end

local function assertIsAchievement(mod_id, achievement_id)
	Assert.Equals('string', type(mod_id), "Argument #1")
	Assert.Equals('string', type(achievement_id), "Argument #2")
	Assert.NotEquals('nil', type(AchievementDictionary:get(mod_id, achievement_id)), "Achievement for mod ".. mod_id .." with id ".. achievement_id .." does not exist")
end

local function toboolean(x)
	if x == nil then
		x = false
	end

	return x and true
end

-- helper object for manipulating objective states
local Objective = {
	-- returns 'objective' in its initial uncompleted state
	getInitialState = function(self, objective)
		if type(objective) == 'table' then
			local result = {}

			for i, obj in pairs(objective) do
				result[i] =  self:getInitialState(obj)
			end
			return result

		elseif type(objective) == 'number' then
			return 0
		end

		return not toboolean(objective)
	end,

	-- returns 'objective' in its completed state
	getCompleteState = function(self, objective)
		local initialState = self:getInitialState(objective)
		return self:getMergedState(initialState, objective)
	end,

	-- merges progress into objective and returns the result.
	-- entries in progress, not found in objective are discarded.
	-- entries in objective, not found in progress remains the same.
	-- number values are added together.
	-- all other values are considered booleans after merge.
	getMergedState = function(self, objective, progress)
		if type(objective) == 'table' then
			local result = {}

			for i, _ in pairs(objective) do
				if progress == nil or progress[i] == nil then
					result[i] = objective[i]
				else
					result[i] = self:getMergedState(objective[i], progress[i])
				end
			end
			return result

		elseif type(objective) == 'number' then
			return objective + (progress or 0)
		end

		return toboolean(progress)
	end,

	-- returns true if objectives in 'measure' are in more or equal
	-- completion state to the same objectives in 'target'
	isProgress = function(self, measure, target, objective_id)
		if objective_id == nil then
			if type(measure) == 'table' then
				local union = true
				for objective_id, _ in pairs(measure) do
					union = union and self:isProgress(measure, target, objective_id)
				end
				return union
			end
		else
			measure = measure[objective_id]
			target = target[objective_id]
		end

		if type(target) == 'number' then
			return (measure or 0) >= target
		else
			return toboolean(measure and target)
		end
	end,

	-- returns an achievement's tooltip formatted according to the
	-- current objective progress
	getFormattedTooltip = function(self, achievement, tooltip, objective_id)
		local objective = achievement.objective
		local tooltip = tooltip or achievement.tooltip
		local progress = achievement:getProgress()
		local substitution_key = "%$"

		if objective_id ~= nil then
			objective = objective[objective_id]
			progress = progress[objective_id]
			substitution_key = "%$".. objective_id

		elseif type(objective) == 'table' then
			for objective_id, _ in pairs(objective) do
				tooltip = self:getFormattedTooltip(achievement, tooltip, objective_id)
			end
		end

		if type(objective) == 'number' then
			tooltip = tooltip:gsub(substitution_key, progress .."/".. objective)

		elseif type(objective) == 'boolean' then
			tooltip = tooltip:gsub(substitution_key, progress and "Complete" or "Incomplete")

		elseif type(objective) == 'string' then
			undone, done = objective:match("(.+)|(.+)")
			tooltip = tooltip:gsub(substitution_key, progress and done or undone)
		end

		return tooltip
	end
}

local Achievement = {}
CreateClass(Achievement)

function Achievement:addReward() end
function Achievement:remReward() end

function Achievement:validateSavedData()
	local initialState = Objective:getInitialState(self.objective)
	local newState = Objective:getMergedState(initialState, self:getProgress())
	writeData(self.mod_id, self.id, newState)
end

function Achievement:getObjectiveCompleteState()
	return Objective:getCompleteState(self.objective)
end

function Achievement:getObjectiveInitialState()
	return Objective:getInitialState(self.objective)
end

function Achievement:completeProgress()
	local completeState = self:getObjectiveCompleteState()
	self:setProgress(completeState)
end

function Achievement:resetProgress()
	local initialState = self:getObjectiveInitialState()
	self:setProgress(initialState)
end

function Achievement:getProgress()
	return readData(self.mod_id, self.id)
end

function Achievement:setProgress(newState)
	assertIsCompatibleObjectiveType(newState, self.objective)

	local wasComplete = self:isComplete()

	writeData(self.mod_id, self.id, newState)

	local isComplete = self:isComplete()

	if wasComplete ~= isComplete then
		if isComplete then
			modApi.toasts:add(self)
			self:addReward()
		else
			self:remReward()
		end
	end
end

function Achievement:addProgress(progress)
	local newState = Objective:getMergedState(self:getProgress(), progress)
	self:setProgress(newState)
end

function Achievement:trigger(progress)

	if progress == nil or progress == true then
		self:completeProgress()
		return

	elseif progress == false then
		self:resetProgress()
		return
	end

	self:addProgress(progress)
end

function Achievement:isComplete(objective_id)
	Assert.Equals({'nil', 'string'}, type(objective_id), "Argument #1")
	assertIsCompatibleObjectiveType(measure, target)
	return Objective:isProgress(self:getProgress(), self.objective, objective_id)
end

function Achievement:isProgress(progress, objective_id)
	Assert.Equals({'nil', 'string'}, type(objective_id), "Argument #2")
	assertIsCompatibleObjectiveType(measure, target)
	return Objective:isProgress(progress, self:getProgress(), objective_id)
end

function Achievement:getTooltip()
	return Objective:getFormattedTooltip(self)
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

	if type(objective) == 'table' then
		for i, obj in pairs(objective) do
			Assert.Equals({'number', 'boolean', 'string'}, type(obj), "Objective ".. i)
		end
	else
		Assert.Equals({'number', 'boolean', 'string'}, type(objective), "Objective")
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
	local mods = AchievementDictionary._mods

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

	Assert.Equals('string', type(mod_id), "mod_id of achievement")
	Assert.Equals('string', type(id), "id of achievement")
	Assert.Equals('string', type(name), "name of achievement")
	Assert.Equals('string', type(image), "image of achievement")
	Assert.Equals({'number', 'boolean', 'string', 'table'}, type(objective), "objective of achievement")
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
	data:validateSavedData()

	return data
end

local function getAchievement(self, mod_id, achievement_id)
	if mod_id and achievement_id then
		assertIsAchievement(mod_id, achievement_id)
		return AchievementDictionary:get(mod_id, achievement_id)
	end

	if mod_id then
		Assert.Equals('string', type(mod_id), "Argument #1")
		return AchievementDictionary._mods[mod_id]
	end

	return AchievementDictionary._mods
end

local function resetAchievement(self, mod_id, achievement_id)
	assertIsAchievement(mod_id, achievement_id)
	local achievement = AchievementDictionary:get(mod_id, achievement_id)
	achievement:reset()
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

local function isAchievementProgress(self, mod_id, achievement_id, progress)
	assertIsAchievement(mod_id, achievement_id)
	local achievement = AchievementDictionary:get(mod_id, achievement_id)
	return achievement:isProgress(progress)
end

local function getAchievementProgress(self, mod_id, achievement_id, objective_id)
	assertIsAchievement(mod_id, achievement_id)
	local achievement = AchievementDictionary:get(mod_id, achievement_id)
	return achievement:getProgress(objective_id)
end

local function achievementsCanBeAdded(self)
	return canAddAchievements
end

modApi.achievements = {
	add = addAchievement,
	get = getAchievement,
	reset = resetAchievement,
	trigger = triggerAchievement,
	addProgress = addAchievementProgress,
	isComplete = isAchievementComplete,
	isProgress = isAchievementProgress,
	getProgress = getAchievementProgress,
	canBeAdded = achievementsCanBeAdded
}

modApi.events.onModsInitialized:subscribe(onModsInitialized)
