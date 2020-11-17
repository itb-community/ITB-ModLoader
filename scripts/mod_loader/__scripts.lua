local scripts = {
	"hard-alter",
	
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

	-- Needs to be loaded out-of-order
	"modui/popup_opengl",

	"tests/__scripts",
}

-- In files loaded via require(), (...) in top-level scope returns
-- the path of the file being loaded
function GetParentPath(path)
	return path:sub(0, path:find("[\\/][^\\/]*[\\/]?$"))
end

--- Return name of the file for the given path
function GetFileName(path)
	return path:match("^.+[\\/]([^\\/]+)$")
end

-- This particular file is loaded by the game itself, so we have
-- to input the path manually, since (...) here returns nil.
local rootpath = "scripts/mod_loader/"
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
