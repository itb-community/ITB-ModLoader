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

local rootpath = "scripts/mod_loader/"
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
