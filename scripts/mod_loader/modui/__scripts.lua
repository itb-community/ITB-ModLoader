local scripts = {
	"root",
	"dialog_helper",

	"windows",
	"mainmenu",
	"hangar",
	"version_string",

	"popup_script-error",
	"popup_version",
	"popup_resource-error",
	"popup_profile-config",
	"popup_gamepad-warning",

	"modcontent",
	"repair_icon_replace",
	"tests_console",
	
	"mod_configuration",
	"pilot_arrange",
	"pilot_deck_selector",
	"palette_arrange",
	"squad_selector",
	"weapon_deck_selector",
	"modloader_configuration",
	"achievements",
	"achievements_squads",
	"toast",

	"modcontent_entries",
}

local rootpath = GetParentPath(...)
for i, filepath in ipairs(scripts) do
	require(rootpath..filepath)
end
