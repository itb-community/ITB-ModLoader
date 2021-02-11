
local canAddPalettes = true
local defaultPaletteOrder

local palettes = {
	index = {},
	hash = {},
	palette = {},
	redirect = {},
	image = {},
	
	getIndex = function(self, hash)
		return self.index[hash]
	end,
	
	getHash = function(self, index)
		return self.hash[index]
	end,
	
	getPalette = function(self, index)
		local hash = self.hash[index]
		if not hash then return nil end
		
		return self.palette[hash]
	end,
	
	getCount = function(self)
		return #self.hash
	end,
	
	addPalette = function(self, hash, palette)
		if self.index[hash] ~= nil then return end
		
		local index = #self.hash + 1
		self.hash[index] = hash
		self.index[hash] = index
		self.palette[hash] = palette
	end,
	
	swap = function(self, idx_a, idx_b)
		local hash_a, hash_b = self.hash[idx_a], self.hash[idx_b]
		
		self.index[hash_a], self.index[hash_b] = idx_b, idx_a
		self.hash[idx_a], self.hash[idx_b] = hash_b, hash_a
		
		self.redirect[idx_a], self.redirect[idx_b] = self:getRedirect(idx_b), self:getRedirect(idx_a)
	end,
	
	getRedirect = function(self, index)
		return self.redirect[index] or index
	end,
	
	getRedirectList = function(self)
		local res = {}
		
		for i,v in pairs(self.redirect) do
			res[v] = i
		end
		
		return res
	end,
	
	setPaletteImage = function(self, index, image)
		local hash = self.hash[index]
		if not hash then return end
		
		self.image[hash] = "img/".. image
	end,
	
	getPaletteImage = function(self, index)
		local hash = self.hash[index]
		if not hash then return nil end
		
		return self.image[hash]
	end
}

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

function modApi.getColorMap(paletteIndex)
	return palettes:getPalette(paletteIndex)
end

function modApi.getColorCount()
	return palettes:getCount()
end

function modApi:canAddPalettes()
	return canAddPalettes
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

local function getVanillaId(paletteIndex)
	return VANILLA_PALETTE_ID[paletteIndex]
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

local function stringize_color(gl_color)
	return string.format("0x%X%X%X%X", gl_color.r, gl_color.g, gl_color.b, gl_color.a)
end

local function getPaletteHash(palette)
	local res = {}
	
	for i = 1, 8 do
		local color = palette[i]
		if color then
			res[i] = stringize_color(color)
		else
			res[i] = ""
		end
	end
	
	return save_table(res)
end

local function saveDefaultPaletteOrder()
	defaultPaletteOrder = shallow_copy(palettes.hash)
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
		for new_index = 2, math.min(11, palettes:getCount()) do
			local palette_id = loadedPaletteOrder[new_index]
			
			if
				palette_id ~= nil                    and
				type(palette_id) == 'string'         and
				palettes:getIndex(palette_id) ~= nil
			then
				local old_index = palettes:getIndex(palette_id)
				
				if old_index ~= new_index and old_index ~= 1 then
					palettes:swap(old_index, new_index)
				end
			end
		end
		
		local redirectList = palettes:getRedirectList()
		
		-- apply new color index offsets to pawn types
		for name, pawnType in pairs(_G) do
			if isPlayerUnitType(pawnType) then
				local newIndex = redirectList[pawnType.ImageOffset+1]
				
				if newIndex and pawnType.ImageOffset ~= newIndex-1 then
					pawnType.ImageOffset = newIndex-1
				end
				
				-- while we are looping through all pawns,
				-- save a pawn using this image offset for
				-- use in palette ui
				local index = pawnType.ImageOffset + 1
				
				if
					palettes:getHash(index) ~= nil         and
					palettes:getPaletteImage(index) == nil
				then
					
					local animation = ANIMS[pawnType.Image .."_ns"]
					if
						type(animation) == 'table'        and
						type(animation.Image) == 'string'
					then
						palettes:setPaletteImage(index, animation.Image)
					end
				end
			end
		end
		
		local new_paletteOrder = {}
		for i = 2, 11 do
			new_paletteOrder[i] = palettes:getHash(i)
		end
		
		config.paletteOrder = new_paletteOrder
	end)
end

local function migrateColorMaps()
	local fromIndex = palettes:getCount() + 1
	local toIndex = GetColorCount()
	
	if fromIndex > toIndex then return end
	
	for i = fromIndex, toIndex do
		local palette = GetColorMap(i)
		local hash = getVanillaId(i) or getFurlId(i) or getPaletteHash(palette)
		
		palettes:addPalette(hash, palette)
	end
	
	GetColorMap = modApi.getColorMap
	GetColorCount = modApi.getColorCount
end

function modApi:finalizePalettes()
	
	migrateColorMaps()
	saveDefaultPaletteOrder()
	loadPaletteOrder()
	
	local playerAnimationHeight = GetColorCount()
	
	for anim_name, animation in pairs(ANIMS) do
		if
			type(animation) == 'table'         and
			type(animation.Height) == 'number' and
			type(animation.Image) == 'string'
		then
			local isPlayerUnitAnimation = self:stringStartsWith(animation.Image, "units/player")
			
			if isPlayerUnitAnimation then
				animation.Height = playerAnimationHeight
			end
		end
	end
	
    -- update base objects that cannot be determined
	-- with Image starting with "units/player"
    ANIMS.MechColors = playerAnimationHeight
    ANIMS.MechIcon.Height = playerAnimationHeight
	
    ANIMS.BaseUnit.Height = 1
    ANIMS.EnemyUnit.Height = 3
	
	-- remove ability to add palettes and
	-- clear these functions for further use.
	canAddPalettes = false
	self.finalizePalettes = nil
end

function modApi:addPalette(palette, id)
	Assert.True(canAddPalettes, "Cannot add palettes after game init")
	Assert.Equals('table', type(palette), "Argument #1")
	Assert.Equals('string', type(id), "Argument #2")
	
	migrateColorMaps()
	
	if palettes:getIndex(id) ~= nil then
		LOGF("A palette with id %s has already been added", id)
		return
	end
	
	local new_palette = {}
	for color_name, color in pairs(palette) do
		local color_index = COLOR_NAME_2_INDEX[color_name]
		
		if color_index then
			if type(color) == 'table' then
				for i = 1, 3 do
					Assert.Equals('number', type(color[i]), string.format("Argument #1 - color %s entry %s", color_name, i))
				end
				
				color = GL_Color(color[1], color[2], color[3])
			end
			
			new_palette[color_index] = color
		end
	end
	
	for i = 1, 8 do
		Assert.Equals('userdata', type(new_palette[i]), string.format("Argument #1 - incomplete palette"))
	end
	
	palettes:addPalette(id, new_palette)
end

function modApi:getPaletteImageOffset(id)
	Assert.Equals('string', type(id), "Argument #1")
	
	local paletteIndex = palettes:getIndex(id)
	Assert.Equals('number', type(paletteIndex), string.format("Palette index for id %s not found", id))
	
	return paletteIndex - 1
end

function modApi:getPaletteIds()
	return shallow_copy(palettes.hash)
end

function modApi:getDefaultPaletteIds()
	return shallow_copy(defaultPaletteOrder)
end

function modApi:getPalette(id)
	return palettes.palette[id]
end

function modApi:getPalettePawnImage(id)
	return palettes.image[id]
end
