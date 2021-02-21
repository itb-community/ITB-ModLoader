local scripts = {
	"vector",
	"init",
	"global",
	"statistics",
	"ftldat",
	"misc",
	"sandbox",
	"config",
	"hooks",
	"data",
	"text",
	"achievement",
	"squad",
	"drops",
	"difficulty",
	"map",
	"skills",
	"savedata",
	"hotkey",
	"board",
	"pawn",
	"localization",
	"compat"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
