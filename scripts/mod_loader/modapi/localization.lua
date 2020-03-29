--[[
	Maps language identifiers to language indices
--]]
Languages = {
	English = 1,
	Chinese_Simplified = 2,
	French = 3,
	German = 4,
	Italian = 5,
	Polish = 6,
	Portuguese_Brazil = 7,
	Russian = 8,
	Spanish = 9,
	Japanese = 10
}

local languageDisplayNames = {}
languageDisplayNames[Languages.English] = Language_English
languageDisplayNames[Languages.Chinese_Simplified] = Language_Chinese_Simplified
languageDisplayNames[Languages.French] = Language_French
languageDisplayNames[Languages.German] = Language_German
languageDisplayNames[Languages.Italian] = Language_Italian
languageDisplayNames[Languages.Polish] = Language_Polish
languageDisplayNames[Languages.Portuguese_Brazil] = Language_Portuguese_Brazil
languageDisplayNames[Languages.Russian] = Language_Russian
languageDisplayNames[Languages.Spanish] = Language_Spanish
languageDisplayNames[Languages.Japanese] = Language_Japanese

--[[
	Returns the index representing the language.
--]]
function modApi:getLanguageIndex()
	return Settings.language
end

--[[
	Returns language identifier given a language index.
--]]
function modApi:getLanguageId(languageIndex)
	assert(type(languageIndex) == "number", "Language index must be a number")

	for k, v in pairs(Languages) do
		if v == languageIndex then
			return k
		end
	end

	return nil
end

--[[
	Returns a table mapping language indices to language display names.
--]]
function modApi:getLanguageDisplayName()
	return languageDisplayNames[self:getLanguageIndex()]
end

function modApi:setText(id, text)
	assert(type(id) == "string", "ID must be a string")
	assert(type(text) == "string", "Text must be a string")

	self.dictionary[id] = text
end

function modApi:getModLoaderDictionariesPath()
	return "scripts/mod_loader/localization"
end

function modApi:getModLoaderDictionary(languageIndex)
	local languageId = modApi:getLanguageId(languageIndex)
	return string.format("%s/dictionary_%s", self:getModLoaderDictionariesPath(), languageId)
end

function modApi:loadLanguage(languageIndex)
	assert(type(languageIndex) == "number", "Language index must be a number")

	local dictionaryFilePath = self:getModLoaderDictionary(languageIndex)
	if self:fileExists(dictionaryFilePath .. ".lua") then
		self.modLoaderDictionary = require(dictionaryFilePath)
	else
		-- Fall back to loading English
		self.modLoaderDictionary = require(self:getModLoaderDictionary(Languages.English))
	end

	self:setupVanillaTexts()

	self.dictionary = {}
end

--[[
	Save default texts so that we can reuse them later.
--]]
function modApi:setupVanillaTexts()
	local t = self.modLoaderDictionary

	for _, v in ipairs(self.squadKeys) do
		t["Squad_Name_" .. v] = GetVanillaText("TipTitle_" .. v)
		t["Squad_Description_" .. v] = GetVanillaText("TipText_" .. v)
	end

	t["Difficulty_Name_Easy"] = GetVanillaText("Toggle_Easy")
	t["Difficulty_Title_Easy"] = GetVanillaText("TipTitle_HangarEasy")
	t["Difficulty_Description_Easy"] = GetVanillaText("TipText_HangarEasy")

	t["Difficulty_Name_Normal"] = GetVanillaText("Toggle_Normal")
	t["Difficulty_Title_Normal"] = GetVanillaText("TipTitle_HangarNormal")
	t["Difficulty_Description_Normal"] = GetVanillaText("TipText_HangarNormal")

	t["Difficulty_Name_Hard"] = GetVanillaText("Toggle_Hard")
	t["Difficulty_Title_Hard"] = GetVanillaText("TipTitle_HangarHard")
	t["Difficulty_Description_Hard"] = GetVanillaText("TipText_HangarHard")
end
