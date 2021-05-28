
-- substitute unreadable characters.
local function formatTexts(texts)
	Assert.Equals('table', type(texts), "Argument #1")

	for i, text in ipairs(texts) do
		text = string.gsub(text,"“","")
		text = string.gsub(text,"”","")
		text = string.gsub(text,"‘","'")
		text = string.gsub(text,"…","...")
		text = string.gsub(text,"’","'")
		text = string.gsub(text,"–","-")
		texts[i] = text
	end
end

local function dialogEvent(event, texts, overwrite)
	if type(texts) == 'string' then
		texts = {texts}
	end

	formatTexts(texts)

	if overwrite then
		return texts
	else
		return add_arrays(event, texts)
	end
end

local function addDialogTable(self, dialogTable, overwrite)
	Assert.Equals('table', type(dialogTable), "Argument #1")

	for event, texts in pairs(dialogTable) do
		self[event] = self[event] or {}
		self[event] = dialogEvent(self[event], texts, overwrite)
	end
end

local function addMissionDialogTable(missionId, dialogTable, overwrite)
	Assert.Equals('string', type(missionId), "Argument #1")
	Assert.Equals('table', type(dialogTable), "Argument #2")

	for event, texts in pairs(dialogTable) do
		local event = missionId.."_"..event

		self[event] = self[event] or {}
		self[event] = dialogEvent(self[event], texts, overwrite)
	end
end

local personality = getmetatable(Personality["Artificial"])
personality.AddDialogTable = addDialogTable
personality.AddMissionDialogTable = addMissionDialogTable
