local scripts = {
	"hard-alter",
	"Cutils",
	
	"classes",

	"sdlext/serialize",
	"sdlext/extensions",
	"sdlext/keycode_lookup",
	"sdlext/cache_surface",

	"ui/__scripts",
	"modui/__scripts",

	"modapi/__scripts",
	"ftldat/__scripts",
	"altered/__scripts",
	"mod_loader",

	"tests/__scripts",
}

-- In files loaded via require(), (...) in top-level scope returns
-- the path of the file being loaded
function GetParentPath(path)
	return path:sub(0, path:find("/[^/]*$"))
end

-- This particular file is loaded by the game itself, so we have
-- to input the path manually, since (...) here returns nil.
local rootpath = "scripts/mod_loader/"
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
