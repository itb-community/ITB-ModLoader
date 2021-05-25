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
	"personalities_csv",
	"achievement",
	"medals",
	"palette",
	"squad",
	"drops",
	"difficulty",
	"map",
	"mission",
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
