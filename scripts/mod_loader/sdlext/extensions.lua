--[[
	Try to run GC if we cross a certain threshold of created
	SDL/sdlext objects, in an attempt to clean them up.
--]]
local gccounter = 0
local function checkGC()
	gccounter = gccounter + 1
	if gccounter > 10000 then
		gccounter = 0
		collectgarbage("collect")
		LOG("sdlext triggered GC")
	end
end

function hex2rgba(hex)
	hex = hex:gsub("#","")
	local l = hex:len()
	assert(l == 6 or l == 8)
	
	local r = tonumber("0x"..hex:sub(1,2))
	local g = tonumber("0x"..hex:sub(3,4))
	local b = tonumber("0x"..hex:sub(5,6))
	if l == 8 then
		local a = tonumber("0x"..hex:sub(7,8))
		return r, g, b, a
	end

	return r, g, b
end

local oldsdltext = sdl.text
function sdl.text(font, textset, text)
	checkGC()

	return oldsdltext(font, textset, text)
end

local oldsdlrgb = sdl.rgb
function sdl.rgb(r, g, b)
	checkGC()

	if type(r) == "string" then
		return oldsdlrgb(hex2rgba(r))
	else
		return oldsdlrgb(r, g, b)
	end
end

local oldsdlrgba = sdl.rgba
function sdl.rgba(r, g, b, a)
	checkGC()

	if type(r) == "string" then
		return oldsdlrgba(hex2rgba(r))
	else
		return oldsdlrgba(r, g, b, a)
	end
end

local resourceDat = sdl.resourceDat("resources/resource.dat")
local resourceDatMtime = os.mtime("resources/resource.dat")
local function checkResource()
	local mtime = os.mtime("resources/resource.dat")
	if resourceDatMtime ~= mtime then
		resourceDatMtime = mtime
		resourceDat = sdl.resourceDat("resources/resource.dat")
		resourceDat:reload()
	end
end

sdlext = {}

function sdlext.font(path,size)
	checkResource()
	checkGC()
	
	local blob = sdl.blobFromResourceDat(resourceDat,path)
	if blob.length==0 then
		return sdl.filefont(path, size)
	end

	return sdl.filefontFromBlob(blob,size)
end

function sdlext.surface(path)
	checkResource()
	checkGC()
	
	local blob = sdl.blobFromResourceDat(resourceDat,path)
	if blob.length==0 then
		return sdl.surface(path)
	end

	return sdl.surfaceFromBlob(blob)
end

function sdlext.squadPalettes()
	local colorMapEnv = {}
	colorMapEnv.GL_Color = function(r, g, b, a)
		if a == nil then
			return sdl.rgb(r, g, b)
		else
			return sdl.rgba(r, g, b, a)
		end
	end

	modApi:loadIntoEnv("scripts/color_map.lua", colorMapEnv)
	local palettes = {}
	for i = 1, colorMapEnv.GetColorCount() do
		palettes[i] = colorMapEnv.GetColorMap(i)
	end

	return palettes
end

function sdlext.config(filename, func)
	local path = GetSavedataLocation()
	os.mkdir(path)

	local obj = persistence.load(path..filename)
	obj = obj or {}
	
	func(obj)
	
	persistence.store(path..filename, obj)
end

local temprect = nil
function drawborder(screen, color, rect, borderwidth)
	if not temprect then temprect = sdl.rect(0,0,0,0) end

	-- left side
	temprect.x = rect.x
	temprect.y = rect.y
	temprect.w = borderwidth
	temprect.h = rect.h
	screen:drawrect(color, temprect)

	-- right side
	temprect.x = rect.x + rect.w - borderwidth
	screen:drawrect(color, temprect)

	-- top side
	temprect.x = rect.x
	temprect.y = rect.y
	temprect.w = rect.w
	temprect.h = borderwidth
	screen:drawrect(color, temprect)

	-- bottom side
	temprect.y = rect.y + rect.h - borderwidth
	screen:drawrect(color, temprect)
end

function drawtri_tl(screen, color, rect)
	if not temprect then temprect = sdl.rect(0,0,0,0) end

	for y = 0, rect.h do
		temprect.x = rect.x
		temprect.y = rect.y + y
		temprect.w = rect.w * (1 - y / rect.h)
		temprect.h = 1

		screen:drawrect(color, temprect)
	end
end

function drawtri_tr(screen, color, rect)
	if not temprect then temprect = sdl.rect(0,0,0,0) end

	for y = 0, rect.h do
		temprect.w = rect.w * (1 - y / rect.h)
		temprect.x = rect.x + rect.w - temprect.w
		temprect.y = rect.y + y
		temprect.h = 1

		screen:drawrect(color, temprect)
	end
end

function drawtri_bl(screen, color, rect)
	if not temprect then temprect = sdl.rect(0,0,0,0) end

	for y = 0, rect.h do
		temprect.x = rect.x
		temprect.y = rect.y + y
		temprect.w = rect.w * (y / rect.h)
		temprect.h = 1

		screen:drawrect(color, temprect)
	end
end

function drawtri_br(screen, color, rect)
	if not temprect then temprect = sdl.rect(0,0,0,0) end

	for y = 0, rect.h do
		temprect.w = rect.w * (y / rect.h)
		temprect.x = rect.x + rect.w - temprect.w
		temprect.y = rect.y + y
		temprect.h = 1

		screen:drawrect(color, temprect)
	end
end

local function rect_contains0(x, y, w, h, px, py)
	return px >= x     and
	       px < x + w  and
	       py >= y     and
	       py < y + h
end

--[[
	rect_contains(rect, px, py)
	OR
	rect_contains(x, y, w, h, px, py)
--]]
function rect_contains(...)
	local a = {...}
	Assert.True(#a == 3 or #a == 6, "Expected 3 or 6 arguments, but got " .. #a)

	if #a == 3 then
		return rect_contains0(
			a[1].x, a[1].y,
			a[1].w, a[1].h,
			a[2],   a[3]
		)
	else
		return rect_contains0(...)
	end
end

function rect_intersects(r1, r2)
	return not (r2.x > r1.x + r1.w or
	            r2.x + r2.w < r1.x or
	            r2.y > r1.y + r1.h or
	            r2.y + r2.h < r1.y)
end

--[[
	rect_equals(rect1, rect2)
	OR
	rect_equals(rect, x, y, w, h)
		x, y, w, and h arguments can be nil, defaulting to 0
--]]
function rect_equals(...)
	local a = {...}
	assert(#a <= 5, "Invalid arguments")

	if #a == 2 then
		return a[1].x == a[2].x and
		       a[1].y == a[2].y and
		       a[1].w == a[2].w and
		       a[1].h == a[2].h
	else
		a[2] = a[2] or 0
		a[3] = a[3] or 0
		a[4] = a[4] or 0
		a[5] = a[5] or 0

		return a[1].x == a[2] and
		       a[1].y == a[3] and
		       a[1].w == a[4] and
		       a[1].h == a[5]
	end
end

--[[
	rect_set(rect1, rect2)
	OR
	rect_set(rect, x, y, w, h)
		x, y, w, and h arguments can be nil, defaulting to 0
--]]
function rect_set(...)
	local a = {...}
	assert(#a <= 5, "Invalid arguments")

	if #a == 2 then
		a[1].x = a[2].x
		a[1].y = a[2].y
		a[1].w = a[2].w
		a[1].h = a[2].h
	else
		a[1].x = a[2] or 0
		a[1].y = a[3] or 0
		a[1].w = a[4] or 0
		a[1].h = a[5] or 0
	end
end

--[[
	draws a Ui element with the draw function of `ui`.
	Keeps the current set clipping rectangle, while 
	occluding anything intersecting with the
	occlusion rectangle `occlusionRect`.
--]]
function sdlext.occlude_draw(ui, widget, screen, occlusionRect)
	if not temprect then temprect = sdl.rect(0,0,0,0) end
	Assert.True(Ui:isSuperclassOf(ui))

	-- Hack. modApi.msDeltaTime is set
	-- to 0 on subsequent draws, to
	-- ensure animations don't advance
	-- faster than they should.
	local tmp = modApi.msDeltaTime
	local wasDrawn = false
	local ox = occlusionRect.x
	local oy = occlusionRect.y
	local ow = occlusionRect.w
	local oh = occlusionRect.h

	local currentClipRect = screen:getClipRect()
	local x, y, w, h
	if currentClipRect then
		x = currentClipRect.x
		y = currentClipRect.y
		w = currentClipRect.w
		h = currentClipRect.h
	else
		x = 0
		y = 0
		w = screen:w()
		h = screen:h()
	end

	for dir = DIR_START, DIR_END do
		if dir == DIR_LEFT then
			temprect.x = x
			temprect.y = y
			temprect.w = math.min(w, ox - x)
			temprect.h = h
		elseif dir == DIR_RIGHT then
			temprect.x = math.max(x, ox + ow)
			temprect.y = y
			temprect.w = x + w - temprect.x
			temprect.h = h
		elseif dir == DIR_UP then
			temprect.x = math.max(x, ox)
			temprect.y = y
			temprect.w = math.min(ox + ow, x + w) - temprect.x
			temprect.h = math.min(h, oy - y)
		elseif dir == DIR_DOWN then
			temprect.x = math.max(x, ox)
			temprect.y = math.max(y, oy + oh)
			temprect.w = math.min(ox + ow, x + w) - temprect.x
			temprect.h = y + h - temprect.y
		end

		if temprect.w > 0 and temprect.h > 0 then
			if wasDrawn then
				modApi.msDeltaTime = 0
			else
				wasDrawn = true
			end

			screen:clip(temprect)
			ui.draw(widget, screen)
			screen:unclip()
		end
	end

	if wasDrawn then
		modApi.msDeltaTime = tmp
	else
		temprect.x = 0
		temprect.y = 0
		temprect.w = 0
		temprect.h = 0

		-- call draw at least once, in case
		-- the ui element relies on draw being
		-- called for other functionality;
		-- like advancing an animation.
		screen:clip(temprect)
		ui.draw(widget, screen)
		screen:unclip()
	end
end
