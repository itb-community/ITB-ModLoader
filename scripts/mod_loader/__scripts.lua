local scripts = {
	"sdlext/serialize",
	"sdlext/extensions",

	"ui/__scripts",
	"modui/__scripts",

	"modapi",
	"ftldat/__scripts",
	"altered",
	"mod_loader",
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
