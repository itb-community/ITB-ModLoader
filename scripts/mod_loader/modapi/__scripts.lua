local scripts = {
	"assert",
	"vector",
	"event",
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
	"squad",
	"drops",
	"difficulty",
	"map",
	"skills",
	"savedata",
	"board",
	"pawn",
	"localization",
	"compat"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
