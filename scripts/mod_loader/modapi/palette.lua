
local VANILLA_PALETTE_ID = {
	"Rift Walkers",
	"Rusting Hulks",
	"Zenith Guard",
	"Blitzkrieg",
	"Steel Judoka",
	"Flame Behemoths",
	"Frozen Titans",
	"Hazardous Mechs",
	"Secret Squad"
}

local COLOR_NAME_2_INDEX = {
	lights = 1,
	main_highlight = 2,
	main_light = 3,
	main_mid = 4,
	main_dark = 5,
	metal_dark = 6,
	metal_mid = 7,
	metal_light = 8,
	PlateHighlight = 1,
	PlateLight = 2,
	PlateMid = 3,
	PlateDark = 4,
	PlateOutline = 5,
	PlateShadow = 6,
	BodyColor = 7,
	BodyHighlight = 8
}

local canAddPalettes = true

local PaletteDictionary = {
	_dictionary = {},
	_array = {},
	add = function(self, id, palette)
		assert(type(id) == 'string')
		assert(type(palette) == 'table')

		local index = #self._array + 1

		palette.id = id
		palette.imageOffset = index
		palette.imageOffsetOrig = index

		self._dictionary[id] = palette
		self._array[#self._array+1] = palette
	end,

	get = function(self, a)
		if type(a) == 'number' then
			return self._array[a]
		else
			return self._dictionary[a]
		end
	end,

	swap = function(self, a, b)
		local paletteA, paletteB
		if type(a) == 'number' then
			paletteA = self._array[a]
		else
			paletteA = self._dictionary[a]
		end

		if type(b) == 'number' then
			paletteB = self._array[b]
		else
			paletteB = self._dictionary[b]
		end

		local indexA = paletteB.imageOffset
		local indexB = paletteA.imageOffset

		paletteA.imageOffset = indexA
		paletteB.imageOffset = indexB
		self._array[indexA] = paletteA
		self._array[indexB] = paletteB
	end,

	size = function(self)
		return #self._array
	end
}

local Palette = {}
CreateClass(Palette)

local new = Palette.new
function Palette:new(...)
	local instance = new(self, ...)

	if rawget(instance, "images") == nil then
		instance.images = {}
	end

	return instance
end

local function ensureImgPrefix(str)
	-- if string starts with "\" or "/"
	if str:find("^[\\/]") then
		str = "img"..str
	-- if string does not start with "img\" or "img/"
	elseif not str:find("^img[\\/]") then
		str = "img/"..str
	end

	return str
end

function Palette:addImage(image)
	table.insert(self.images, ensureImgPrefix(image))
end

function modApi.getColorMap(paletteIndex)
	local palette = PaletteDictionary:get(paletteIndex)
	if palette == nil then return nil end

	return palette.colorMap
end

function modApi.getColorCount()
	local count = PaletteDictionary:size()

	if count > 11 and sdlext.isHangar() then
		return 11
	end

	return count
end

local function isPlayerUnitType(pawnType)
	if
		type(pawnType) == 'table'                     and
		type(pawnType.Image) == 'string'              and
		type(pawnType.ImageOffset) == 'number'        and
		type(ANIMS[pawnType.Image]) == 'table'        and
		type(ANIMS[pawnType.Image].Image) == 'string'
	then
		local image = ANIMS[pawnType.Image].Image
		return modApi:stringStartsWith(image, "units/player")
	end

	return false
end

local function getFurlId(paletteIndex)
	if FURL_COLORS then
		for id, index in pairs(FURL_COLORS) do
			if index == paletteIndex - 1 then
				return id
			end
		end
	end

	return nil
end

local function buildPaletteId(paletteIndex)
	if modApi.currentMod == nil then return -1 end

	local mod = mod_loader.mods[modApi.currentMod]

	local i = 1
	while PaletteDictionary:get(mod.id..i) ~= nil do
		i = i + 1
	end

	return mod.id..i
end

local function buildPaletteName(paletteIndex)
	if modApi.currentMod == nil then return "Unnamed" end

	local mod = mod_loader.mods[modApi.currentMod]

	return mod.name
end

local function buildPaletteColorMap(colorMap)
	local gl_colorMap = {}
	for color_name, color in pairs(colorMap) do
		local color_index = COLOR_NAME_2_INDEX[color_name]

		if color_index then
			if type(color) == 'table' then
				for i = 1, 3 do
					Assert.Equals('number', type(color[i]), string.format("Argument #1 - color %s entry %s", color_name, i))
				end

				color = GL_Color(color[1], color[2], color[3])
			end

			gl_colorMap[color_index] = color
		end
	end

	for i = 1, 8 do
		Assert.Equals('userdata', type(gl_colorMap[i]), string.format("Argument #1 - incomplete colorMap"))
	end

	return gl_colorMap
end

local function buildPaletteImages(palette)
	local images = palette.images or palette.Images

	Assert.Equals({'nil', 'table'}, type(images), "images of palette")

	if images == nil then
		images = { palette.image or palette.Image }
	end

	for i, image in ipairs(images) do
		Assert.Equals({'nil', 'string'}, type(image), string.format("image #%s of palette", i))
		images[i] = ensureImgPrefix(image)
	end

	return images
end

local function loadPaletteOrder()
	sdlext.config("modcontent.lua", function(config)
		local loadedPaletteOrder = config.paletteOrder or {}

		-- fetch palette ids from modcontent.lua.
		-- ignore palette #1 because it is forced.
		-- ignore palettes beyond 11 because they
		-- are not selectable in the hangar.
		-- ignore palettes beyond our current
		-- palette count.
		for new_index = 2, math.min(11, PaletteDictionary:size()) do
			local palette_id = loadedPaletteOrder[new_index]

			if palette_id ~= nil and type(palette_id) == 'string' then
				local palette = PaletteDictionary:get(palette_id)

				if palette ~= nil then
					local old_index = palette.imageOffset
					
					if old_index ~= new_index and old_index ~= 1 then
						PaletteDictionary:swap(old_index, new_index)
					end
				end
			end
		end

		-- build a list of imageOffset redirects in order
		-- to correct already set imageOffsets
		local redirectList = {}
		for imageOffset, palette in ipairs(PaletteDictionary._array) do
			redirectList[palette.imageOffsetOrig] = imageOffset
		end

		-- apply new color index offsets to pawn types
		for name, pawnType in pairs(_G) do
			if isPlayerUnitType(pawnType) then
				local newIndex = redirectList[pawnType.ImageOffset + 1]

				if newIndex and pawnType.ImageOffset ~= newIndex - 1 then
					pawnType.ImageOffset = newIndex - 1
				end

				-- while we are looping through all pawns,
				-- save a pawn using this image offset for
				-- use in palette ui
				local palette = PaletteDictionary:get(pawnType.ImageOffset + 1)

				if palette ~= nil then
					local animation = ANIMS[pawnType.Image .."_ns"]
					if
						type(animation) == 'table'        and
						type(animation.Image) == 'string'
					then
						palette:addImage(animation.Image)
					end
				end
			end
		end

		-- build new palette order to save to config
		local new_paletteOrder = {}
		for imageOffset = 2, 11 do
			local palette = PaletteDictionary:get(imageOffset)

			if palette ~= nil then
				new_paletteOrder[imageOffset] = palette.id
			end
		end

		config.paletteOrder = new_paletteOrder
	end)
end

local function migrateColorMaps()
	local fromIndex = PaletteDictionary:size() + 1
	local toIndex = GetColorCount()

	if fromIndex > toIndex then return end

	for i = fromIndex, toIndex do
		local colorMap = GetColorMap(i)
		local id = VANILLA_PALETTE_ID[i] or getFurlId(i) or buildPaletteId()
		local name = i > 9 and buildPaletteName() or nil

		local palette = Palette:new{
			name = name,
			colorMap = colorMap,
		}
		PaletteDictionary:add(id, palette)
	end

	GetColorMap = modApi.getColorMap
	GetColorCount = modApi.getColorCount
end

function finalizePalettes()
	migrateColorMaps()
	loadPaletteOrder()

	local playerAnimationHeight = GetColorCount()

	for anim_name, animation in pairs(ANIMS) do
		if
			type(animation) == 'table'         and
			type(animation.Height) == 'number' and
			type(animation.Image) == 'string'
		then
			local isPlayerUnitAnimation = modApi:stringStartsWith(animation.Image, "units/player")
			
			if isPlayerUnitAnimation then
				animation.Height = playerAnimationHeight
			end
		end
	end

	-- update base objects that cannot be determined
	-- with Image; starting with "units/player"
	ANIMS.MechColors = playerAnimationHeight
	ANIMS.MechIcon.Height = playerAnimationHeight

	ANIMS.BaseUnit.Height = 1
	ANIMS.EnemyUnit.Height = 3

	-- remove ability to add palettes after init
	canAddPalettes = false
end

function modApi:canAddPalettes()
	return canAddPalettes
end

function modApi:addPalette(palette)
	Assert.ModInitializingOrLoading("Cannot add palette at this time")
	Assert.True(canAddPalettes, "Cannot add palettes after game init")
	Assert.Equals('table', type(palette), "Argument #1")

	migrateColorMaps()

	local id = palette.id or palette.ID or buildPaletteId()
	local name = palette.name or palette.Name or buildPaletteName()
	local colorMap = buildPaletteColorMap(palette.colorMap or palette)
	local images = buildPaletteImages(palette)

	Assert.Equals('string', type(id), "id of palette")
	Assert.Equals('string', type(name), "name of palette")

	local data = Palette:new{
		name = name,
		colorMap = colorMap,
		images = images
	}

	Assert.Equals('nil', type(PaletteDictionary:get(id)), "Palette with id ".. id .." already exist")

	PaletteDictionary:add(id, data)
end

function modApi:getPaletteImageOffset(id)
	Assert.Equals('string', type(id), "Argument #1")

	local palette = PaletteDictionary:get(id)
	Assert.NotEquals('nil', type(palette), string.format("Palette for id %s not found", id))

	return palette.imageOffset - 1
end

function modApi:getCurrentPaletteOrder()
	local currentPaletteOrder = {}

	for imageOffset, palette in ipairs(PaletteDictionary._array) do
		local id = palette.id

		currentPaletteOrder[imageOffset] = id
	end

	return currentPaletteOrder
end

function modApi:getDefaultPaletteOrder()
	local defaultPaletteOrder = {}

	for _, palette in ipairs(PaletteDictionary._array) do
		local id = palette.id
		local imageOffset_orig = palette.imageOffsetOrig

		defaultPaletteOrder[imageOffset_orig] = id
	end

	return defaultPaletteOrder
end

function modApi:getPalette(id)
	return PaletteDictionary:get(id)
end

modApi.events.onModInitialized:subscribe(migrateColorMaps)
modApi.events.onModsInitialized:subscribe(finalizePalettes)
