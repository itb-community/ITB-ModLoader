local scripts = {
	"root",
	"dialog_helper",

	"version_string",
	"error_warning",
	"modcontent",
	
	"mod_configuration",
	"pilot_arrange",
	"squad_selector",
	"modloader_configuration",

	"modcontent_entries",
}

local rootpath = "scripts/mod_loader/modui/"
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
