
local resourceDat = sdl.resourceDat("resources/resource.dat")
local resourceDatMtime = os.mtime("resources/resource.dat")
local function checkResource()
	local mtime = os.mtime("resources/resource.dat")
	if resourceDatMtime ~= mtime then
		resourceDatMtime = mtime
		resourceDat:reload()
	end
end

sdlext = {}

function sdlext.font(path,size)
	checkResource()
	
	local blob = sdl.blobFromResourceDat(resourceDat,path)
	if blob.length==0 then
		return sdl.filefont(path, size)
	end

	return sdl.filefontFromBlob(blob,size)
end

function sdlext.surface(path)
	checkResource()
	
	local blob = sdl.blobFromResourceDat(resourceDat,path)
	if blob.length==0 then
		return sdl.surface(path)
	end
	
	return sdl.surfaceFromBlob(blob)
end

function sdlext.squadPalettes()
	local GetColorMapOld = GetColorMap
	local GL_ColorOld = GL_Color
	function GL_Color(r,g,b)
		return sdl.rgb(r,g,b)
	end
	
	require("scripts/color_map")
	local res = {}
	
	for i=1,GetColorCount() do
		res[i]=GetColorMap(i)
	end
	
	GetColorMap = GetColorMapOld
	GL_Color = GL_ColorOld

	return res
end

function sdlext.config(filename,func)
	local path = os.getKnownFolder(5).."/My Games/Into The Breach"
	os.mkdir(path)

	local obj = persistence.load(path.."/"..filename)
	obj = obj or {}
	
	func(obj)
	
	persistence.store(path.."/"..filename, obj)
end
