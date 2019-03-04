local scripts = {
	"init",
	"global",
	"ftldat",
	"misc",
	"config",
	"hooks",
	"data",
	"text",
	"squad",
	"difficulty",
	"map",
	"skills"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
