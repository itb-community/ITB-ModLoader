local scripts = {
	"uieventloop",
	"errorwarning",
	"modcontent",
	"modconfiguration",
	"pilotarrange",
	"squadselector",
	"modloaderconfiguration",
	"modui",
}

local rootpath = "scripts/mod_loader/modui/"
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
