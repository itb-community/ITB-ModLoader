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
local languageNames = {}
for name, index in pairs(Languages) do
	languageNames[index] = name
end

local languageDisplayNames = {}
languageDisplayNames[Languages.English] = Global_Texts.Language_English
languageDisplayNames[Languages.Chinese_Simplified] = Global_Texts.Language_Chinese_Simplified
languageDisplayNames[Languages.French] = Global_Texts.Language_French
languageDisplayNames[Languages.German] = Global_Texts.Language_German
languageDisplayNames[Languages.Italian] = Global_Texts.Language_Italian
languageDisplayNames[Languages.Polish] = Global_Texts.Language_Polish
languageDisplayNames[Languages.Portuguese_Brazil] = Global_Texts.Language_Portuguese_Brazil
languageDisplayNames[Languages.Russian] = Global_Texts.Language_Russian
languageDisplayNames[Languages.Spanish] = Global_Texts.Language_Spanish
languageDisplayNames[Languages.Japanese] = Global_Texts.Language_Japanese

--[[
	Returns the index representing currently selected language.
--]]
function modApi:getLanguageIndex()
	local index = Settings and Settings.language or nil
	if index == nil or languageNames[index] == nil then
		return Languages.English
	end
	return index
end

--[[
	Returns language identifier for the specified language index.
--]]
function modApi:getLanguageId(languageIndex)
	languageIndex = languageIndex or self:getLanguageIndex()
	assert(type(languageIndex) == "number", "Language index must be a number")

	return languageNames[index] or "English"
end

--[[
	Returns display name for the specified language index.
--]]
function modApi:getLanguageDisplayName(languageIndex)
	languageIndex = languageIndex or self:getLanguageIndex()
	assert(type(languageIndex) == "number", "Language index must be a number")

	return languageDisplayNames[languageIndex]
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
