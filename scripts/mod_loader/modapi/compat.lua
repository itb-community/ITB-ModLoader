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

local oldGetStatusTooltip = GetStatusTooltip
function GetStatusTooltip(id)
	local ret = oldGetStatusTooltip(id)

	-- if it returns the ID, it means it was not found, fallback to global table
	if ret[1] == id and STATUS_TOOLTIPS[id] ~= nil then
		return STATUS_TOOLTIPS[id]
	end

	return ret
end

-- ///////////////////////////////////////////////////////////////////////////////////
-- compatibility code for KnightMiner's customPalettes
local palettes = { VERSION = "1" }
CUSTOM_PALETTES = palettes

function palettes.addPalette(...)
	for _, palette in ipairs({...}) do
		modApi:addPalette(palette)
	end
end

function palettes.getOffset(id)
	return modApi:getPaletteImageOffset(id)
end
