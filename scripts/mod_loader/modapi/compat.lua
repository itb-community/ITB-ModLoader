-- Deprecated things kept around for backwards compatibility

function modApi:getText(id, r1, r2, r3)
	assert(type(id) == "string", "Expected string, got: "..type(id))
	local result = GetText(id, r1, r2, r3)

	if not result then
		LOG("Attempt to reference non-existing text id '"..id.."', "..debug.traceback())
	end

	return result
end

function modApi:overwriteText(id, str)
	modApi:setText(id, str)
end

-- ///////////////////////////////////////////////////////////////////////////////////
-- Override global text tables with metatables that automatically register texts
-- so that the new version of the game recognizes them.
local textsMetatable = {
	__index = function(self, key)
		return GetText(key)
	end,
	__newindex = function(self, key, value)
		value = GetText(value)
		modApi:setText(key, value)
	end
}
modApi.texts = setmetatable({}, textsMetatable)

local globalTextsMetatable = {
	__newindex = function(self, key, value)
		value = GetText(value)
		rawset(self, key, value)

		modApi:setText(key, value)
	end
}
Global_Texts = setmetatable(Global_Texts, globalTextsMetatable)

function GetStatusTooltip(id)
	local title_text = "Status_"..id.."_Title"

	if IsText(title_text) then
		return {title_text, "Status_"..id.."_Text"}
	end

	if STATUS_TOOLTIPS[id] ~= nil then
		return STATUS_TOOLTIPS[id]
	else
		return { id, "NOT FOUND"}
	end
end
