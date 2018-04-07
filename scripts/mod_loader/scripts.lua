local scripts = {
	"scripts/sdlext/serialize",
	"scripts/sdlext/extensions",
	"scripts/ui/ui",
	"scripts/sdlext/uieventloop",
	"scripts/sdlext/modcontent",
	"scripts/sdlext/modconfiguration",
	"scripts/sdlext/pilotarrange",
	"scripts/sdlext/squadselector",
	"scripts/sdlext/sdlext",
	
	"scripts/mod_loader/modapi",
	"scripts/mod_loader/lua-struct",
	"scripts/kaitai_struct_lua_runtime-master/kaitaistruct",
	"scripts/mod_loader/altered",
	"scripts/mod_loader/mod_loader",
}

for i, filepath in ipairs(scripts) do
	require(filepath)
end