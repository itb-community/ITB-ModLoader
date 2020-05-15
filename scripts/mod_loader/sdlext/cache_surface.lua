--[[
	provides functionality for caching sdl surfaces.
	
	function:
	---------
	sdlext.getSurface(tbl)
	
	tbl
	---
	a table of surface info. Transformations are applied in the order listed here.
	
		arg        type         description
		-----------------------------------------------------------------
		path       string       path of image in resource.dat (required)
		scale      number       scale of image (default: nil)
		outline    table        see below (default: nil)
		colormap   table        see below (default: nil)
		multiply   color        color tint of the image
		grayscale  boolean      if true, the image will be turned to grayscale
		-----------------------------------------------------------------
		
	outline
	-------
	a table of outline info.
	
		arg        type         description
		-----------------------------------------------------------------
		border     number       outline thickness (default: 1)
		color      sdl.rgb      outline color (default: white)
		-----------------------------------------------------------------
	
	colormap
	--------
	an array of color substitutions, with the following pattern:
	
	{ sdl.rgb(), sdl.rgb(), .. etc }
	
	where color index 1 is substituted for 2; 3 for 4, and so on.
]]

local DequeList = require("scripts/mod_loader/deque_list")

sdlext.surface_cache_max = 100
local cache = DequeList()
local indices = {}

local keys = {
	"path",
	"scale",
	"outline",
	"colormap",
	"multiply",
	"grayscale"
}

local stringize = {
	path = function(path) return path end,
	
	scale = function(scale) return scale end,
	
	outline = function(outline)
		local border = outline.border or 1
		local c = outline.color or deco.colors.white
		return string.format("%s,%s,%s,%s,%s,", border, c.r, c.g, c.b, c.a)
	end,
	
	colormap = function(colormap)
		local ret = ""
		for _, c in ipairs(colormap) do
			ret = ret .. string.format("%s,%s,%s,%s,", c.r, c.g, c.b, c.a)
		end
		
		return ret
	end,

	color = function(c)
		return string.format("%s,%s,%s,%s,", c.r, c.g, c.b, c.a)
	end
}

-- gets a cached surface, or creates one and caches it.
local function getSurface(key, fn)
	local index = indices[key]
	local surface
	
	if index then
		-- retrieve cached surface
		surface = cache[index].surface
	else
		while cache:size() > sdlext.surface_cache_max do
			-- remove oldest surface
			local element = cache:popRight()
			indices[element.key] = nil
		end
		
		-- create a new surface
		surface = fn()
		cache:pushLeft{ key = key, surface = surface }
		indices[key] = cache.first
	end
	
	return surface
end

-- converts an input table into a stringized table that can be deterministically be hashed.
local function getHash(tbl)
	-- ensure final key contains all sub keys.
	for _, i in ipairs(keys) do
		tbl[i] = tbl[i] or ""
	end
	
	return save_table(tbl)
end

-- creates and caches new surfaces and returns cached surface.
function sdlext.getSurface(tbl)
	assert(type(tbl) == 'table')
	assert(type(tbl.path) == 'string')
	
	local key = { path = stringize.path(tbl.path) }
	local surface = getSurface(
		getHash(key),
		function() return sdlext.surface(tbl.path) end
	)
	
	if tbl.scale then
		assert(type(tbl.scale) == 'number')
		key.scale = stringize.scale(tbl.scale)
		surface = getSurface(
			getHash(key),
			function() return sdl.scaled(tbl.scale, surface) end
		)
	end
	
	if tbl.outline then
		assert(type(tbl.outline) == 'table')
		key.outline = stringize.outline(tbl.outline)
		surface = getSurface(
			getHash(key),
			function() return sdl.outlined(surface, tbl.outline.border or 1, tbl.outline.color or deco.colors.white) end
		)
	end

	if tbl.colormap then
		assert(type(tbl.colormap) == 'table')
		key.colormap = stringize.colormap(tbl.colormap)
		surface = getSurface(
			getHash(key),
			function() return sdl.colormapped(surface, tbl.colormap) end
		)
	end

	if tbl.multiply then
		assert(type(tbl.multiply) == 'userdata')
		key.multiply = stringize.color(tbl.multiply)
		surface = getSurface(
			getHash(key),
			function() return sdl.multiply(surface, tbl.multiply) end
		)
	end

	if tbl.grayscale then
		assert(type(tbl.grayscale) == 'boolean')
		key.grayscale = "true,"
		surface = getSurface(
			getHash(key),
			function() return sdl.grayscale(surface) end
		)
	end
	
	return surface
end