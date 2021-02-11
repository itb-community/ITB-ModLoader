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
		modApi:setText(key, value)
	end
}
modApi.texts = setmetatable({}, textsMetatable)

local globalTextsMetatable = {
	__newindex = function(self, key, value)
		rawset(self, key, value)

		modApi:setText(key, value)
	end
}
Global_Texts = setmetatable(Global_Texts, globalTextsMetatable)

local tilesMetatable = {
	__newindex = function(self, key, value)
		assert(type(value) == "table", "Value assigned to TILE_TOOLTIPS table must be a table.")
		rawset(self, key, value)

		local titleKey = string.format("Tile_%s_Title", key)
		local textKey = string.format("Tile_%s_Text", key)

		modApi:setText(titleKey, value[1])
		modApi:setText(textKey, value[2])
	end
}
TILE_TOOLTIPS = setmetatable(TILE_TOOLTIPS, tilesMetatable)

local statusMetatable = {
	__newindex = function(self, key, value)
		assert(type(value) == "table", "Value assigned to STATUS_TOOLTIPS table must be a table.")
		rawset(self, key, value)

		local titleKey = string.format("Status_%s_Title", key)
		local textKey = string.format("Status_%s_Text", key)

		modApi:setText(titleKey, value[1])
		modApi:setText(textKey, value[2])
	end
}
STATUS_TOOLTIPS = setmetatable(STATUS_TOOLTIPS, statusMetatable)

-- ///////////////////////////////////////////////////////////////////////////////////
-- compatibility code for KnightMiner's customPalettes
local palettes = { VERSION = "1" }
CUSTOM_PALETTES = palettes

function palettes.addPalette(...)
	for _, palette in ipairs({...}) do
		modApi:addPalette(palette, palette.ID)
	end
end

function palettes.getOffset(id)
	return modApi:getPaletteIndex(id)
end
