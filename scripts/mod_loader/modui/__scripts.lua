local scripts = {
	"root",
	"dialog_helper",

	"windows",
	"mainmenu",
	"hangar",
	"version_string",

	"popup_version",
	"popup_script-error",
	"popup_resource-error",
	"popup_profile-config",
	"popup_gamepad-warning",

	"modcontent",
	"extra_difficulty",
	"repair_icon_replace",
	"tests_console",
	
	"mod_configuration",
	"pilot_arrange",
	"palette_arrange",
	"squad_selector",
	"weapon_deck_selector",
	"modloader_configuration",

	"modcontent_entries",
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
