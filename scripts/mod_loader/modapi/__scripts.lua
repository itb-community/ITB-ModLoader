local scripts = {
	"init",
	"global",
	"ftldat",
	"misc",
	"sandbox",
	"config",
	"hooks",
	"data",
	"text",
	"squad",
	"difficulty",
	"map",
	"skills",
	"savedata",
	"gamestate",
	"game",
	"board",
	"pawn",
	"mechedit"
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
